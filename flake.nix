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
                    system = "aarch64-darwin";
                    modules = [ 
                        ./nix-darwin/default.nix
                        home-manager.darwinModules.home-manager
                        {
                            home-manager.useGlobalPkgs = true;
                            home-manager.useUserPackages = true;
                            home-manager.users.danielsp_45 = import ./home-manager/darwin/daniels-air.nix;
                        }
                    ];
                };
            };
        };
}
