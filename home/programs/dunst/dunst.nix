{ mkSymlink, ... }:
{
  xdg.configFile."dunst/dunstrc" = mkSymlink "dunstrc";
}
