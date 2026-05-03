{ mkSymlink, ... }:
{
  services.swayosd.enable = true;
  xdg.configFile."swayosd/config.toml" = mkSymlink "config.toml";
  xdg.configFile."swayosd/style.css" = mkSymlink "style.css";
}
