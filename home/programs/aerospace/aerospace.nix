{ mkSymlink, ... }:
{
  xdg.configFile."aerospace/aerospace.toml" = mkSymlink "aerospace.toml";
}
