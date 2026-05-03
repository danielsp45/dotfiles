{ pkgs, ... }:
{
  home.packages = with pkgs; [
    lutris
    prismlauncher
    wine
    qbittorrent
    bitwig-studio
    mangohud
  ];
}
