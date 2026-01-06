# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, zen-browser, ... }:

{
	# Enable nix flakes
	nix.settings.experimental-features = [ "nix-command" "flakes" ];

  imports = [
		../syncthing.nix
		../networking.nix
    ../internationalisation.nix
    ../programs.nix
    ../fonts.nix
    ../audio.nix
    ../display-manager.nix
    ../misc.nix
	];

	# Bootloader.
  # Lanzaboote currently replaces the systemd-boot module.
  # This setting is usually set to true in configuration.nix
  # generated at installation time. So we force it to false
  # for now.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

	networking.hostName = "trooper"; # Define your hostname.
	# networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

	# Define a user account. Don't forget to set a password with ‘passwd’.
	users.users.daniel = {
		isNormalUser = true;
		description = "Daniel Pereira";
		extraGroups = [ "networkmanager" "wheel" "input" "daniel" "docker" "dialout" "uucp" ];
		shell = pkgs.zsh;
		packages = with pkgs; [
			kdePackages.kate
			#  thunderbird
		];
	};

  systemd.services = {
    ModemManager = {
      enable = false;
      restartIfChanged = false;
    };
  };

	services.cron = {
		enable = true;
		# This creates a crontab entry for the user "daniel"
		systemCronJobs = [
			# Backup the system every day at 3am
		];
	};

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
