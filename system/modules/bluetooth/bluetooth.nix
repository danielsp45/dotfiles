{ pkgs, ... }:
{
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  hardware.bluetooth.settings = {
    General.Experimental = true;
  };

  hardware.enableRedistributableFirmware = true;

  services.blueman.enable = true;
}
