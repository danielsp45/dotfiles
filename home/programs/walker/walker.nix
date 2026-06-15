{ pkgs, mkSymlink, ... }:
{
  home.packages = [ pkgs.walker pkgs.elephant ];
  xdg.configFile."walker" = mkSymlink "config";
}
