{ pkgs, mkSymlink, ... }:
{
  home.packages = [ pkgs.walker pkgs.elephant pkgs.hyprlauncher ];
  xdg.configFile."walker" = mkSymlink "config";
}
