{
    description = "My Home Manager flake";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        nix-darwin = {
            url = "github:LnL7/nix-darwin";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = { self, nixpkgs, home-manager, nix-darwin, ... }:
        let
            system = "aarch64-darwin";
            pkgs = nixpkgs.legacyPackages.${system};

        in {
            homeConfigurations = {
                "daniels-air" = home-manager.lib.homeManagerConfiguration {
                    pkgs = nixpkgs.legacyPackages."aarch64-darwin";
                    modules = [ ./home-manager/darwin/daniels-air.nix ];
                };

                "dsp-server" = home-manager.lib.homeManagerConfiguration {
                    pkgs = nixpkgs.legacyPackages."x86_64-linux";
                    modules = [ ./home-manager/linux/dsp-server.nix ];
                };

                "gsd-cluster" = home-manager.lib.homeManagerConfiguration {
                    pkgs = nixpkgs.legacyPackages."x86_64-linux";
                    modules = [ ./home-manager/linux/gsd-cluster.nix ];
                };
            };

            darwinConfigurations = {
                "daniels-air" = nix-darwin.lib.darwinSystem {
                    modules = [ 
                        ./nix-darwin/flake.nix 
                        configuration
                        home-manager.darwinModules."daniels-air" {
                            modules = [ ./home-manager/darwin/daniels-air.nix ];
                        }
                    ];
                };
            };
        };
}
