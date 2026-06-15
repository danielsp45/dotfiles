{
  description = "Daniel's Nix configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
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

      elixirOverlay = elixir-overlay.overlays.default;

      trooperOverlays = [
        zenBrowserOverlay
        claudecode.overlays.default
        feynmanOverlay
        elixirOverlay
        (final: prev: {
          openldap = prev.openldap.overrideAttrs (_: { doCheck = false; });
        })
      ];

      stormOverlays = [ zenBrowserOverlay claudecode.overlays.default feynmanOverlay elixirOverlay ];

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
