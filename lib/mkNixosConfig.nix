{ nixpkgs, home-manager }:
system: hostname: cfg:
let
  lib = nixpkgs.lib;

  mkSystemModule = import ../system/lib/mkSystemModule.nix { inherit lib; };
  systemModules = map
    (name: mkSystemModule name (import ../system/modules/${name}/${name}.nix))
    (lib.attrNames (builtins.readDir ../system/modules));

  mkHomeModule = import ../home/lib/mkHomeModule.nix { inherit lib; };
  homeModules = map
    (name: mkHomeModule name (import ../home/programs/${name}/${name}.nix))
    (lib.attrNames (builtins.readDir ../home/programs));

  baseHMModules = [ ../home ../home/lib ] ++ homeModules;
in
nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit hostname; } // (cfg.specialArgs or { });
  modules = [
    ../system
    home-manager.nixosModules.home-manager
    {
      nixpkgs.overlays = cfg.overlays or [ ];
      nixpkgs.config.allowUnfree = true;
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.extraSpecialArgs = { inherit hostname; username = "daniel"; };
      home-manager.sharedModules = baseHMModules;
      home-manager.users.daniel = ../home/users/daniel.nix;
    }
  ] ++ systemModules ++ (cfg.extraModules or [ ]);
}
