{ pkgs, mkSymlink, ... }:
{
  home.packages = [ pkgs.waybar ];
  xdg.configFile."waybar" = mkSymlink "config";
}
