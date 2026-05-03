{ mkSymlink, ... }:
{
  xdg.configFile."btop/btop.conf" = mkSymlink "btop.conf";
}
