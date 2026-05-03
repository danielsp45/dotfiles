{ pkgs, ... }:
{
  home.packages = with pkgs; [
    typst
    roboto
    source-sans-pro
  ];
}
