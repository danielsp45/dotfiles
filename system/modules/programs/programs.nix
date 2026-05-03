{ pkgs, ... }:
{
  programs.dconf.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    pciutils
    arandr
    zen-browser
    android-tools
    adb-sync
  ];
}
