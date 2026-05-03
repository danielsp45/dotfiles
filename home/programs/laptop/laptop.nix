{ pkgs, ... }:
{
  home.packages = with pkgs; [
    sshfs
    mutagen
    via
  ];
}
