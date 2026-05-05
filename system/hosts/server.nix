{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.zfs ];
  dotfiles.modules.internationalisation.enable = true;
  dotfiles.modules.networking.enable = true;
  dotfiles.modules.openssh.enable = true;
  dotfiles.modules.docker.enable = true;
  dotfiles.modules.tailscale.enable = true;
  dotfiles.modules.server.enable = true;
  dotfiles.modules.nfs-server.enable = true;

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sdf";
  boot.loader.grub.useOSProber = true;

  boot.kernelPackages = pkgs.linuxPackages_6_6;

  boot.zfs.extraPools = [ "storage" ];

  services.zfs.autoScrub.enable = true;

  users.users.daniel.extraGroups = [
    "networkmanager" "wheel" "input" "daniel" "docker"
  ];
}
