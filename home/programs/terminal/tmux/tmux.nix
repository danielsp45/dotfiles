{ pkgs, mkSymlink, ... }:
{
  home.packages = [ pkgs.tmux ];
  home.file.".tmux.conf" = mkSymlink "tmux.conf";
}
