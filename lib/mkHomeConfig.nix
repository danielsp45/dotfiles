{ nixpkgs, home-manager }:
system: hostname: username: cfg:
let
  lib = nixpkgs.lib;
  mkHomeModule = import ../home/lib/mkHomeModule.nix { inherit lib; };
  homeModules = map
    (name: mkHomeModule name (import ../home/programs/${name}/${name}.nix))
    (lib.attrNames (builtins.readDir ../home/programs));
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
