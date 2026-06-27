{ pkgs, ... }:
{
  home.packages = with pkgs; [
    lutris
    prismlauncher
    wine
    qbittorrent
    mangohud
    bitwig-studio
    lmms
    qt5.qtwayland
    wowup-cf
  ];
}
