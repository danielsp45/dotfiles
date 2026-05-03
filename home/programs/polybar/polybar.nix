{ pkgs, mkSymlink, ... }:
{
  home.packages = [ pkgs.polybar ];
  xdg.configFile."polybar" = mkSymlink "config";
}
