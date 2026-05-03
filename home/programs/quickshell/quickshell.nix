{ pkgs, mkSymlink, ... }:
{
  home.packages = [ pkgs.quickshell ];
  xdg.configFile."quickshell" = mkSymlink "config";
}
