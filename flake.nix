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
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
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
      lanzaboote,
      claudecode,
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

      trooperOverlays = [
        zenBrowserOverlay
        claudecode.overlays.default
        feynmanOverlay
        (final: prev: {
          openldap = prev.openldap.overrideAttrs (_: { doCheck = false; });
        })
      ];

      stormOverlays = [ zenBrowserOverlay claudecode.overlays.default feynmanOverlay ];

    in
    {
      nixosConfigurations = {
        trooper = mkNixosConfig "x86_64-linux" "trooper" {
          overlays = trooperOverlays;
          extraModules = [ lanzaboote.nixosModules.lanzaboote ];
        };

        storm = mkNixosConfig "x86_64-linux" "storm" {
          overlays = stormOverlays;
        };

        server = mkNixosConfig "x86_64-linux" "server" { };
      };

      homeConfigurations = {
        "daniel@trooper" = mkHomeConfig "x86_64-linux" "trooper" "daniel" {
          overlays = trooperOverlays;
        };
        "daniel@storm" = mkHomeConfig "x86_64-linux" "storm" "daniel" {
          overlays = stormOverlays;
        };
        "daniel@server" = mkHomeConfig "x86_64-linux" "server" "daniel" { };
        "ubuntu-vagrant" = mkHomeConfig "aarch64-linux" "ubuntu-vagrant" "daniel" { };
        "gsd-cluster" = mkHomeConfig "x86_64-linux" "gsd-cluster" "daniel" { };
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
