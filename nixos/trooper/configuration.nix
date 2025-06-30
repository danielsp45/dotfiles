# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:
{
	# Enable nix flakes
	nix.settings.experimental-features = [ "nix-command" "flakes" ];

	# Bootloader.
	boot.loader.systemd-boot.enable = true;
	boot.loader.efi.canTouchEfiVariables = true;

	networking.hostName = "trooper"; # Define your hostname.
	# networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

	# Configure network proxy if necessary
	# networking.proxy.default = "http://user:password@proxy:port/";
	# networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

	# Enable networking
	networking.networkmanager.enable = true;
	networking.resolvconf.enable = false;  # let NM manage DNS
	networking.useHostResolvConf = false;
	services.resolved.enable = true;
	systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;


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


	services.displayManager.ly.enable = true;
	services.displayManager.sddm.wayland.enable = true;
    programs.hyprland.enable = true;
	programs.xwayland.enable = true;
	# Optional, hint electron apps to use wayland:
	environment.sessionVariables = {
		NIXOS_OZONE_WL = "1";
		CLUTTER_BACKEND = "wayland";
		SDL_VIDEODRIVER = "wayland";
		QT_QPA_PLATFORM = "wayland";
		GDK_BACKEND = "wayland";
	};


	# Enable CUPS to print documents.
	services.printing.enable = true;

	# Enable sound with pipewire.
	services.pulseaudio.enable = false;
	security.rtkit.enable = true;
	services.pipewire = {
		enable = true;
		alsa.enable = true;
		alsa.support32Bit = true;
		pulse.enable = true;
		# If you want to use JACK applications, uncomment this
		#jack.enable = true;

		# use the example session manager (no others are packaged yet so this is enabled by default,
		# no need to redefine it in your config for now)
		#media-session.enable = true;
	};

	# Enable touchpad support (enabled default in most desktopManager).
	# services.xserver.libinput.enable = true;

	# Define a user account. Don't forget to set a password with ‘passwd’.
	users.users.daniel = {
		isNormalUser = true;
		description = "Daniel Pereira";
		extraGroups = [ "networkmanager" "wheel" ];
		shell = pkgs.zsh;
		packages = with pkgs; [
			kdePackages.kate
			#  thunderbird
		];
	};

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
		openrgb-with-all-plugins
		# polybar
		(polybar.override {
			pulseSupport = true;
		})
		xorg.xinit
		pciutils
		arandr
		blueman
		flameshot
		pulseaudio
		playerctl
		dunst
		ly
		networkmanagerapplet
	];

	programs.dconf.enable = true;


	services.tailscale.enable = true;

	services.hardware.openrgb.enable = true;

	hardware.bluetooth.enable = true; # enables support for bluetooth
	hardware.bluetooth.powerOnBoot = true;

	programs.steam = {
		enable = true;
		remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
		dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
		localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
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

	services.cron = {
		enable = true;
		# This creates a crontab entry for the user "daniel"
		systemCronJobs = [
			# Backup the system every day at 3am
		];
	};


	fonts.packages = with pkgs; [ 
		noto-fonts 
		font-awesome
		nerd-fonts.jetbrains-mono
		nerd-fonts.fira-code
		nerd-fonts.jetbrains-mono
		nerd-fonts.hack
		nerd-fonts.ubuntu-mono
		nerd-fonts.caskaydia-cove
	];

	# Some programs need SUID wrappers, can be configured further or are
	# started in user sessions.
	# programs.mtr.enable = true;
	# programs.gnupg.agent = {
	#   enable = true;
	#   enableSSHSupport = true;
	# };

	# List services that you want to enable:

	# Open ports in the firewall.
	# networking.firewall.allowedTCPPorts = [ ... ];
	# networking.firewall.allowedUDPPorts = [ ... ];
	# Or disable the firewall altogether.
	# networking.firewall.enable = false;


	# This value determines the NixOS release from which the default
	# settings for stateful data, like file locations and database versions
	# on your system were taken. It‘s perfectly fine and recommended to leave
	# this value at the release version of the first install of this system.
	# Before changing this value read the documentation for this option
	# (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
	system.stateVersion = "25.05"; # Did you read the comment?
}
