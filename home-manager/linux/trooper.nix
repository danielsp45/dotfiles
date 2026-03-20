{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # development tools
    tlaplus
    tlaplusToolbox
    jdk21
    cmake
    esphome
    duckdb
    vagrant

    # system utilities
    qbittorrent
    amdgpu_top
    mangohud
    rocmPackages.rocm-smi
    lm_sensors
    cifs-utils
    borgmatic
    borgbackup
    droidcam
    mission-center

    # clipboard
    screen

    # productivity
    libreoffice
    bitwig-studio

    # multimedia
    zoom

    # gaming & launchers
    lutris
    prismlauncher
    wine

    # theming
    hicolor-icon-theme

    # GPU packages
    rocmPackages.rpp
  ];

  imports = [ ./common.nix ];
}
