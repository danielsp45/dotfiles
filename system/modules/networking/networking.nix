{ pkgs, ... }:
{
  networking.networkmanager.enable = true;
  networking.networkmanager.plugins = [ pkgs.networkmanager-openvpn ];
  networking.resolvconf.enable = false;
  networking.useHostResolvConf = false;
  networking.nameservers = [ "1.1.1.1" ];
  networking.enableIPv6 = false;
  services.resolved.enable = true;
  systemd.services.NetworkManager-wait-online.enable = false;

  networking.firewall.allowedTCPPorts = [
    53317 # localsend
    4747
  ];
  networking.firewall.allowedUDPPorts = [
    53317 # localsend
    4747
  ];

  environment.systemPackages = [ pkgs.networkmanagerapplet ];
}
