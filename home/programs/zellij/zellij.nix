{ pkgs, mkSymlink, ... }:
{
  home.packages = [ pkgs.zellij ];
  xdg.configFile."zellij/config.kdl" = mkSymlink "config.kdl";
  xdg.configFile."zellij/layouts" = mkSymlink "layouts";
}
