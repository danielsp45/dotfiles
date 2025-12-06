# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, zen-browser, ... }:

{
	# Enable nix flakes
	nix.settings.experimental-features = [ "nix-command" "flakes" ];

  imports = [
		../networking.nix
    ../internationalisation.nix
    ../programs.nix
    ../fonts.nix
    ../audio.nix
    ../display-manager.nix
    ../misc.nix
	];

	# Bootloader.
	boot.loader.systemd-boot.enable = true;
	boot.loader.efi.canTouchEfiVariables = true;

	networking.hostName = "storm"; # Define your hostname.
	# networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.


	# Define a user account. Don't forget to set a password with ‘passwd’.
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

	# Some programs need SUID wrappers, can be configured further or are
	# started in user sessions.
	# programs.mtr.enable = true;
	# programs.gnupg.agent = {
	#   enable = true;
	#   enableSSHSupport = true;
	# };

	# List services that you want to enable:

	# Open ports in the firewall.
	# networking.firewall.allowedTCPPorts = [ 24800 ];
	# networking.firewall.allowedUDPPorts = [ ... ];
	# Or disable the firewall altogether.


	# This value determines the NixOS release from which the default
	# settings for stateful data, like file locations and database versions
	# on your system were taken. It‘s perfectly fine and recommended to leave
	# this value at the release version of the first install of this system.
	# Before changing this value read the documentation for this option
	# (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
	system.stateVersion = "25.05"; # Did you read the comment?
}
