{ pkgs, mkSymlink, ... }:
{
  home.packages = [ pkgs.alacritty ];
  xdg.configFile."alacritty/alacritty.toml" = mkSymlink "alacritty.toml";
}
