{
  description = "Daniel's Nix configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    # Pinned to the last nixpkgs rev where zotero builds. Current unstable
    # dropped the Firefox ESR 140 that zotero needs, breaking the build
    # (NixOS/nixpkgs#568692). Drop this once the upstream fix lands.
    nixpkgs-zotero.url = "github:NixOS/nixpkgs/7a0f122f5090cf4c2ade2a13a0e229d4e19ba71f";
    claudecode.url = "github:sadjow/claude-code-nix";
    nixos = {
      url = "github:nixos/nixpkgs/nixpkgs-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    elixir-overlay = {
      url = "github:zoedsoupe/elixir-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-zotero,
      home-manager,
      nix-darwin,
      zen-browser,
      claudecode,
      elixir-overlay,
      ...
    }:
    let
      lib = nixpkgs.lib;

      mkNixosConfig = import ./lib/mkNixosConfig.nix { inherit nixpkgs home-manager; };
      mkHomeConfig = import ./lib/mkHomeConfig.nix { inherit nixpkgs home-manager; };

      zenBrowserOverlay = final: prev: {
        zen-browser = zen-browser.packages.${final.stdenv.hostPlatform.system}.default;
      };

      feynmanOverlay = final: prev: {
        feynman = final.callPackage ./pkgs/feynman { };
      };

      iptvnatorOverlay = final: prev: {
        iptvnator = final.callPackage ./pkgs/iptvnator { };
      };

      zoteroOverlay = final: prev: {
        zotero = (import nixpkgs-zotero {
          inherit (final.stdenv.hostPlatform) system;
          config.allowUnfree = true;
        }).zotero;
      };

      elixirOverlay = elixir-overlay.overlays.default;

      trooperOverlays = [
        zenBrowserOverlay
        claudecode.overlays.default
        feynmanOverlay
        iptvnatorOverlay
        elixirOverlay
        zoteroOverlay
        (final: prev: {
          openldap = prev.openldap.overrideAttrs (_: { doCheck = false; });
        })
      ];

      stormOverlays = [ zenBrowserOverlay claudecode.overlays.default feynmanOverlay iptvnatorOverlay elixirOverlay zoteroOverlay ];

      devOverlays = [ elixirOverlay ];

    in
    {
      nixosConfigurations = {
        trooper = mkNixosConfig "x86_64-linux" "trooper" {
          overlays = trooperOverlays;
        };

        storm = mkNixosConfig "x86_64-linux" "storm" {
          overlays = stormOverlays;
        };

        pandora = mkNixosConfig "x86_64-linux" "pandora" { };
      };

      homeConfigurations = {
        "daniel@trooper" = mkHomeConfig "x86_64-linux" "trooper" "daniel" {
          overlays = trooperOverlays;
        };
        "daniel@storm" = mkHomeConfig "x86_64-linux" "storm" "daniel" {
          overlays = stormOverlays;
        };
        "daniel@pandora" = mkHomeConfig "x86_64-linux" "pandora" "daniel" { };
        "daniel@hermes" = mkHomeConfig "aarch64-linux" "hermes" "daniel" { overlays = devOverlays; };
        "ubuntu-vagrant" = mkHomeConfig "aarch64-linux" "ubuntu-vagrant" "daniel" { overlays = devOverlays; };
        "gsd-cluster" = mkHomeConfig "x86_64-linux" "gsd-cluster" "daniel" { overlays = devOverlays; };
      };

      darwinConfigurations = {
        "daniels-air" = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            ./nix-darwin/default.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.daniel = import ./home-manager/darwin/daniels-air.nix;
            }
          ];
        };
      };
    };
}
