{ pkgs, mkSymlink, ... }:
{
  home.packages = [ pkgs.fastfetch ];
  xdg.configFile."fastfetch/config.jsonc" = mkSymlink "config.jsonc";
}
