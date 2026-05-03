{ pkgs, mkSymlink, ... }:
{
  home.packages = [ pkgs.ghostty ];
  xdg.configFile."ghostty/config" = mkSymlink "config";
  xdg.configFile."ghostty/screensaver.conf" = mkSymlink "screensaver.conf";
}
