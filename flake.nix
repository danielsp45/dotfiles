{
  description = "My Home Manager flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }: {
    defaultPackage.aarch64-darwin = home-manager.defaultPackage.aarch64-darwin;
 
    homeConfigurations = {
	    # TODO: Modify "your.username" below to match your username
        "danielsp_45" = home-manager.lib.homeManagerConfiguration {
        system = "aarch64-darwin"; # TODO: replace with x86_64-linux on Linux
        homeDirectory = "/Users/danielsp_45"; # TODO: make this match your home directory
        username = "danielsp_45";
        configuration.imports = [ ./home.nix ];
      };
    };
  };
}
