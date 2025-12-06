{ config, pkgs, lib, ... }:

{
	# Enable CUPS to print documents.
	services.printing.enable = true;

  services.udisks2.enable = true;
  services.gvfs.enable = true;
}
