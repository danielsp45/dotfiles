{ mkSymlink, ... }:
{
  xdg.configFile."keychron/keychron_k2_pro_ansi_rgb.layout.json" =
    mkSymlink "keychron_k2_pro_ansi_rgb.layout.json";
}
