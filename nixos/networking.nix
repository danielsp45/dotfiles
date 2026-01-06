{ config, pkgs, lib, ... }:

{
	networking.networkmanager.enable = true;
  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openvpn
  ];
	networking.resolvconf.enable = false;  # let NM manage DNS
	networking.useHostResolvConf = false;
  networking.nameservers = [ "1.1.1.1" ];
	services.resolved.enable = true;
	systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;

  networking.firewall.allowedTCPPorts = [
    53317
  ];
  networking.firewall.allowedUDPPorts = [
    53317
  ];
}
