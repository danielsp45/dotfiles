{ lib, pkgs, ... }:
{
  dotfiles.modules.audio.enable = true;
  dotfiles.modules.networking.enable = true;
  dotfiles.modules.fonts.enable = true;
  dotfiles.modules.display-manager.enable = true;
  dotfiles.modules.internationalisation.enable = true;
  dotfiles.modules.printing.enable = true;
  dotfiles.modules.bluetooth.enable = true;
  dotfiles.modules.steam.enable = true;
  dotfiles.modules.docker.enable = true;
  dotfiles.modules.tailscale.enable = true;
  dotfiles.modules.openssh.enable = true;
  dotfiles.modules.flatpak.enable = true;
  dotfiles.modules.firefox.enable = true;
  dotfiles.modules.openrgb.enable = true;
  dotfiles.modules.syncthing.enable = true;
  dotfiles.modules.programs.enable = true;
  dotfiles.modules.borgbackup.enable = true;
  dotfiles.modules.obs.enable = true;
  dotfiles.modules.virtualisation.enable = true;
  dotfiles.modules.nfs-client.enable = true;

  # Pinned to 6.6 LTS to avoid MT7921 BT regression (wmt func ctrl bug backported to 6.18/6.12)
  # Remove once the fix lands in nixpkgs
  boot.kernelPackages = pkgs.linuxPackages_6_6;

  # Lanzaboote replaces systemd-boot for secure boot
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
    configurationLimit = 3;
  };

  users.users.daniel.extraGroups = [
    "networkmanager" "wheel" "input" "daniel" "docker" "dialout" "uucp" "libvirtd" "bluetooth"
  ];

  systemd.services.ModemManager = {
    enable = false;
    restartIfChanged = false;
  };

  services.cron.enable = true;

  nix.settings.cores = 8;
}
