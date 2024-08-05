{
    description = "My Home Manager flake";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = { self, nixpkgs, home-manager, ... }:
        let
            system = "aarch64-darwin";  # TODO: make this dynamic
            pkgs = nixpkgs.legacyPackages.${system};

        in {
            homeConfigurations = {
                "darwin" = home-manager.lib.homeManagerConfiguration {
                    pkgs = nixpkgs.legacyPackages."aarch64-darwin";
                    modules = [ ./home-manager/darwin.nix ];
                };

                "linux" = home-manager.lib.homeManagerConfiguration {
                    pkgs = nixpkgs.legacyPackages."x86_64-linux";
                    modules = [ ./home-manager/linux.nix ];
                };
            };
        };
}
