{
    description = "Daniel's Nix configuration";

	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
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
    };

    outputs = { self, nixpkgs, home-manager, nix-darwin, ... }:
        let

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
                            home-manager.users.daniel = import ./home-manager/darwin/daniels-air.nix;
                        }
                    ];
                };
            };

			nixosConfigurations = {
				nixos = nixpkgs.lib.nixosSystem {
					system = "x86_64-linux";
					modules = [
						./nixos/configuration.nix
						home-manager.nixosModules.home-manager
						{
							home-manager.useGlobalPkgs = true;
							home-manager.useUserPackages = true;
							home-manager.users.daniel = import ./home-manager/linux/nixos.nix;
						}
					];
				};
			};
        };
}
