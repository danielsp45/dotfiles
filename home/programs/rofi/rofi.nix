{ mkSymlink, ... }:
{
  xdg.configFile."rofi" = mkSymlink "config";
}
