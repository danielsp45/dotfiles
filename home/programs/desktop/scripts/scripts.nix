{ mkSymlink, ... }:
{
  home.file.".local/share/config/bin" = mkSymlink "bin";
}
