{
  hostname,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hosts/${hostname}/hardware.nix
    ./hosts/${hostname}.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.hostName = hostname;

  programs.zsh.enable = true;
  programs.nix-ld.enable = true;

  users.users.daniel = {
    isNormalUser = true;
    description = "Daniel Pereira";
    shell = pkgs.zsh;
  };

  system.stateVersion = "25.05";
}
