{ mkSymlink, ... }:
{
  xdg.configFile."espanso/config" = mkSymlink "config";
  xdg.configFile."espanso/match" = mkSymlink "match";
}
