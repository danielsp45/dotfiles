{ pkgs, ... }:
{
  home.packages = with pkgs; [
    amdgpu_top
    rocmPackages.rocm-smi
    rocmPackages.rpp
    lm_sensors
  ];
}
