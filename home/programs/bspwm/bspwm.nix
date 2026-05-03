{ pkgs, mkSymlink, ... }:
{
  home.packages = with pkgs; [ bspwm sxhkd ];
  xdg.configFile."bspwm/bspwmrc" = mkSymlink "bspwmrc";
  xdg.configFile."sxhkd/sxhkdrc" = mkSymlink "sxhkdrc";
}
