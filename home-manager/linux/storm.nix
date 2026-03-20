{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # development tools
    zed-editor
    sshfs
    mutagen

    # system utilities
    via
  ];

  imports = [ ./common.nix ];
}
