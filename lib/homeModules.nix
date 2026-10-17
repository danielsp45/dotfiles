# Discovers home modules at home/programs/<group>/<name>/<name>.nix
{ lib }:
let
  mkHomeModule = import ../home/lib/mkHomeModule.nix { inherit lib; };
  root = ../home/programs;
  subdirs = path: lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir path));
in
lib.concatMap
  (group:
    map
      (name: mkHomeModule name "${group}/${name}" (import (root + "/${group}/${name}/${name}.nix")))
      (subdirs (root + "/${group}")))
  (subdirs root)
