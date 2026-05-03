{ pkgs, ... }:
{
  home.packages = with pkgs; [
    tlaplus
    tlaplusToolbox
    jdk21
    cmake
    esphome
    duckdb
    vagrant
    cifs-utils
    borgmatic
    borgbackup
    droidcam
    mission-center
    screen
  ];
}
