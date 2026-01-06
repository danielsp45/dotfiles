# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
imports =
[ # Include the results of the hardware scan.
./hardware-configuration.nix
./services.nix
];

# Bootloader.
boot.loader.grub.enable = true;
boot.loader.grub.device = "/dev/sda";
boot.loader.grub.useOSProber = true;

networking.hostName = "nixos"; # Define your hostname.
# networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

# Configure network proxy if necessary
# networking.proxy.default = "http://user:password@proxy:port/";
# networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

# Enable networking
networking.networkmanager.enable = true;
networking.nameservers = [ "127.0.0.1" "::1" ];

# Set your time zone.
time.timeZone = "Europe/Lisbon";

# Select internationalisation properties.
i18n.defaultLocale = "en_US.UTF-8";

i18n.extraLocaleSettings = {
LC_ADDRESS = "pt_PT.UTF-8";
LC_IDENTIFICATION = "pt_PT.UTF-8";
LC_MEASUREMENT = "pt_PT.UTF-8";
LC_MONETARY = "pt_PT.UTF-8";
LC_NAME = "pt_PT.UTF-8";
LC_NUMERIC = "pt_PT.UTF-8";
LC_PAPER = "pt_PT.UTF-8";
LC_TELEPHONE = "pt_PT.UTF-8";
LC_TIME = "pt_PT.UTF-8";
};

users.users.daniel = {
isNormalUser = true;
description = "Daniel Pereira";
extraGroups = [ "networkmanager" "wheel" "input" "daniel" "docker" ];
shell = pkgs.zsh;
packages = with pkgs; [
kdePackages.kate
#  thunderbird
];
};

# List packages installed in system profile. To search, run:
# $ nix search wget
programs.zsh.enable = true;

# Install firefox.
programs.firefox.enable = true;

# Allow unfree packages
nixpkgs.config.allowUnfree = true;

# List packages installed in system profile. To search, run:
# $ nix search wget
environment.systemPackages = with pkgs; [
vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
wget
neofetch
git
borgbackup
docker
docker-compose      # if you want docker-compose
];

services.tailscale = {
enable = true;
useRoutingFeatures = "both";
extraUpFlags = [
"set --advertise-exit-node"
];
};

services.openssh = {
enable = true;
ports = [ 22 ];
settings = {
PasswordAuthentication = true;
AllowUsers = null; # Allows all users by default. Can be [ "user1" "user2" ]
UseDns = true;
X11Forwarding = false;
PermitRootLogin = "prohibit-password"; # "yes", "without-password", "prohibit-password", "forced-commands-only", "no"
};
};



programs.nix-ld.enable = true;

# This value determines the NixOS release from which the default
# settings for stateful data, like file locations and database versions
# on your system were taken. It‘s perfectly fine and recommended to leave
# this value at the release version of the first install of this system.
# Before changing this value read the documentation for this option
# (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
system.stateVersion = "25.05"; # Did you read the comment?

}
