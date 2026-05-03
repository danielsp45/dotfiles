{ pkgs, mkSymlink, ... }:
{
  home.packages = [ pkgs.walker ];
  xdg.configFile."walker" = mkSymlink "config";
}
