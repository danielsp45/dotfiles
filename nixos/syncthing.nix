{ config, pkgs, lib, ... }:

{
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    user = "daniel";
    configDir = "/home/daniel/.config/syncthing";
  };
}
