{ nixpkgs, home-manager }:
system: hostname: username: cfg:
let
  lib = nixpkgs.lib;
  homeModules = import ./homeModules.nix { inherit lib; };
in
home-manager.lib.homeManagerConfiguration {
  pkgs = nixpkgs.legacyPackages.${system};
  extraSpecialArgs = { inherit hostname username; } // (cfg.extraSpecialArgs or { });
  modules = [
    {
      nixpkgs.overlays = cfg.overlays or [ ];
      nixpkgs.config.allowUnfree = true;
      home.username = username;
      home.homeDirectory = "/home/${username}";
    }
    ../home
    ../home/lib
    ../home/users/${username}.nix
  ] ++ homeModules;
}
