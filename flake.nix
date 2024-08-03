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
            username = builtins.getEnv "USER";
            home = builtins.getEnv "HOME";
        in {
            defaultPackage.${system} = home-manager.defaultPackage.${system};
 
            homeConfigurations = {
                username = home-manager.lib.homeManagerConfiguration {
                    system = system;
                    homeDirectory = home;
                    username = username;
                    configuration.imports = [ ./home.nix ];
                };
            };
        };
}
