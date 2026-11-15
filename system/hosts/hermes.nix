{ pkgs, ... }:
{
  dotfiles.modules.audio.enable = true;
  dotfiles.modules.networking.enable = true;
  dotfiles.modules.fonts.enable = true;
  dotfiles.modules.display-manager.enable = true;
  dotfiles.modules.internationalisation.enable = true;
  dotfiles.modules.printing.enable = true;
  dotfiles.modules.bluetooth.enable = true;
  dotfiles.modules.docker.enable = true;
  dotfiles.modules.tailscale.enable = true;
  dotfiles.modules.openssh.enable = true;
  dotfiles.modules.flatpak.enable = true;
  dotfiles.modules.firefox.enable = true;
  dotfiles.modules.syncthing.enable = true;
  dotfiles.modules.programs.enable = true;
  dotfiles.modules.nfs-client.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # T2 Mac: nixos-hardware.nixosModules.apple-t2 + the patched kernel are
  # wired up in flake.nix (extraModules), since they need the flake's
  # nixos-hardware input in scope.
  hardware.apple-t2.kernelChannel = "stable";

  # Wi-Fi and Bluetooth firmware for T2 Macs
  hardware.firmware = [ (pkgs.stdenvNoCC.mkDerivation {
    name = "brcm-firmware";
    src = ./hermes/firmware/brcm;
    installPhase = ''
      mkdir -p $out/lib/firmware/brcm
      cp -r * $out/lib/firmware/brcm/
    '';
  }) ];

  users.users.daniel.extraGroups = [
    "networkmanager" "wheel" "input" "daniel" "docker"
  ];
}
