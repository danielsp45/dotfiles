{
  description = "Daniel's Nix configuration";

  nixConfig = {
    extra-substituters = [
      "https://cache.soopy.moe"
    ];
    extra-trusted-public-keys = [ "cache.soopy.moe-1:0RZVsQeR+GOh0VQI9rvnHz55nVXkFardDqfm4+afjPo=" ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    # Pinned to the last nixpkgs rev where zotero builds. Current unstable
    # dropped the Firefox ESR 140 that zotero needs, breaking the build
    # (NixOS/nixpkgs#568692). Drop this once the upstream fix lands.
    nixpkgs-zotero.url = "github:NixOS/nixpkgs/7a0f122f5090cf4c2ade2a13a0e229d4e19ba71f";
    claudecode.url = "github:sadjow/claude-code-nix";
    nixos = {
      url = "github:nixos/nixpkgs/nixos-unstable";
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
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    elixir-overlay = {
      url = "github:zoedsoupe/beam-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-zotero,
      nixos-hardware,
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
        elixirOverlay
        zoteroOverlay
        (final: prev: {
          openldap = prev.openldap.overrideAttrs (_: { doCheck = false; });
        })
      ];

      stormOverlays = [ zenBrowserOverlay claudecode.overlays.default feynmanOverlay elixirOverlay zoteroOverlay ];

      devOverlays = [ elixirOverlay ];

      # Workaround: five t2linux patches fail on linux_6_18 = 6.18.63 due to
      # stable-series backports that changed context lines. Remove this block
      # once nixos-hardware syncs its stable.json past a commit that contains
      # these rebased patches.
      hermesT2KernelModule =
        { pkgs, lib, ... }:
        let
          stableJson = builtins.fromJSON
            (builtins.readFile "${nixos-hardware}/apple/t2/pkgs/linux-t2/stable.json");

          t2Patches = builtins.filter (p: p != null) (map
            (p:
              if p.name == "2008-i915-4-lane-quirk-for-mbp15-1.patch"
              then {
                name = p.name;
                patch = pkgs.fetchurl {
                  name = "2008-i915-4-lane-quirk-for-mbp15-1.patch";
                  url = "https://raw.githubusercontent.com/t2linux/linux-t2-patches"
                    + "/dd9b845c30b3212ac5cbd7c18d0fc0bedb13e4fb"
                    + "/2008-i915-4-lane-quirk-for-mbp15-1.patch";
                  hash = "sha256-gTYP7WHV/Qulobdi1nNdYsv1CWgkM8pGvsCFQ+rvhrw=";
                };
              }
              else if p.name == "3001-applesmc-convert-static-structures-to-drvdata.patch"
              then {
                name = p.name;
                patch = ./system/hosts/hermes/patches/3001-applesmc-convert-static-structures-to-drvdata.patch;
              }
              else if p.name == "4001-asahi-trackpad.patch"
              then {
                name = p.name;
                patch = pkgs.fetchurl {
                  name = "4001-asahi-trackpad.patch";
                  url = "https://raw.githubusercontent.com/t2linux/linux-t2-patches"
                    + "/dd9b845c30b3212ac5cbd7c18d0fc0bedb13e4fb"
                    + "/4001-asahi-trackpad.patch";
                  hash = "sha256-RuYI0t+rMu29wSkVT4suYJgGzS1ZruN/HBZWkLivlDw=";
                };
              }
              else if p.name == "4004-HID-magicmouse-Add-support-for-trackpads-found-on-T2.patch"
              then {
                name = p.name;
                patch = pkgs.fetchurl {
                  name = "4004-HID-magicmouse-Add-support-for-trackpads-found-on-T2.patch";
                  url = "https://raw.githubusercontent.com/t2linux/linux-t2-patches"
                    + "/dd9b845c30b3212ac5cbd7c18d0fc0bedb13e4fb"
                    + "/4004-HID-magicmouse-Add-support-for-trackpads-found-on-T2.patch";
                  hash = "sha256-kUnbtl/54cihscirl9kP0Gsot7bdP0rYKlj6gQ10hk0=";
                };
              }
              else if p.name == "4005-HID-magicmouse-fix-regression-breaking-support-for-M.patch"
              then null
              else {
                inherit (p) name;
                patch = pkgs.fetchurl {
                  inherit (p) name hash;
                  url = stableJson.base_url + p.name;
                };
              })
            stableJson.patches);

          linuxT2 = pkgs.linux_6_18.override {
            pname = "linux-t2";
            structuredExtraConfig = with lib.kernel; {
              APPLE_BCE = module;
              APPLE_GMUX = module;
              APFS_FS = module;
              BRCMFMAC = module;
              BT_BCM = module;
              BT_HCIBCM4377 = module;
              BT_HCIUART_BCM = yes;
              BT_HCIUART = module;
              HID_APPLETB_BL = module;
              HID_APPLETB_KBD = module;
              HID_APPLE = module;
              HID_MAGICMOUSE = module;
              DRM_APPLETBDRM = module;
              HID_SENSOR_ALS = module;
              SND_PCM = module;
              STAGING = yes;
            };
            kernelPatches = t2Patches;
          };
        in {
          boot.kernelPackages = lib.mkForce (pkgs.linuxPackagesFor linuxT2);
        };

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

        hermes = mkNixosConfig "x86_64-linux" "hermes" {
          overlays = stormOverlays;
          extraModules = [
            nixos-hardware.nixosModules.apple-t2
            hermesT2KernelModule
          ];
        };
      };

      homeConfigurations = {
        "daniel@trooper" = mkHomeConfig "x86_64-linux" "trooper" "daniel" {
          overlays = trooperOverlays;
        };
        "daniel@storm" = mkHomeConfig "x86_64-linux" "storm" "daniel" {
          overlays = stormOverlays;
        };
        "daniel@pandora" = mkHomeConfig "x86_64-linux" "pandora" "daniel" { };
        "daniel@hermes" = mkHomeConfig "x86_64-linux" "hermes" "daniel" { overlays = stormOverlays; };
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
