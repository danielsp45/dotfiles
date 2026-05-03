{ pkgs, mkSymlink, ... }:
{
  home.packages = with pkgs; [ git lazygit ];
  home.file.".gitconfig" = mkSymlink "gitconfig";
}
