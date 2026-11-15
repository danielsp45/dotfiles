{ pkgs, ... }:
{
  home.packages = with pkgs; [
    tlaplus
    tlaplusToolbox
    jdk21
    cmake
    esphome
    duckdb
    cifs-utils
    borgmatic
    borgbackup
    droidcam
    mission-center
    screen
  ];
}
