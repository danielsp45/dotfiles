{ mkSymlink, ... }:
{
  home.file.".zshrc" = mkSymlink "linux/zshrc";
}
