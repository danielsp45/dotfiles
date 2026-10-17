{ pkgs, mkSymlink, ... }:
{
  home.packages = [ pkgs.dunst ];
  xdg.configFile."dunst/dunstrc" = mkSymlink "dunstrc";
}
