{ pkgs, ... }:
{
  home.packages = with pkgs; [
    cloudflared
    smartmontools
    busybox
  ];
}
