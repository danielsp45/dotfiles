{ pkgs, ... }:
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

  boot.kernelPackages = pkgs.linuxPackages;

  nixpkgs.config.permittedInsecurePackages = [ "electron-39.8.10" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 3;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.daniel.extraGroups = [
    "networkmanager" "wheel" "input" "daniel" "docker" "dialout" "uucp" "libvirtd" "bluetooth" "video"
  ];

  services.usbmuxd.enable = true;
  environment.systemPackages = [ pkgs.libimobiledevice ];

  systemd.services.ModemManager = {
    enable = false;
    restartIfChanged = false;
  };

  services.cron.enable = true;

  nix.settings.cores = 8;

  # xdg-desktop-portal 1.18+ reads /proc/<pid>/root to verify app identity for
  # screen capture requests; ptrace_scope=1 blocks this for non-parent processes
  boot.kernel.sysctl."kernel.yama.ptrace_scope" = 0;
}
