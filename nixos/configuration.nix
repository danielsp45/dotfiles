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

	networking.hostName = "nixos"; # Define your hostname.
	# networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

	# Configure network proxy if necessary
	# networking.proxy.default = "http://user:password@proxy:port/";
	# networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

	# Enable networking
	networking.networkmanager.enable = true;
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


	# Enable the KDE Plasma Desktop Environment.
	# services.displayManager.sddm.enable = true;
	# services.desktopManager.plasma6.enable = true;

	# Configure keymap in X11
	services.xserver.xkb = {
		layout = "us";
		variant = "";
	};
	# Enable the X11 windowing system.
	# You can disable this if you're only using the Wayland session.

	services.xserver = {
		enable = true;

		desktopManager = {
			xterm.enable = false;
		};

		displayManager = {
			defaultSession = "none+i3";
		};

		windowManager.i3 = {
			enable = true;
			extraPackages = with pkgs; [
				dmenu #application launcher most people use
				i3status # gives you the default i3 status bar
				i3lock #default i3 screen locker
				i3blocks #if you are planning on using i3blocks over i3status
			];
		};
	};

	# Enable CUPS to print documents.
	services.printing.enable = true;

	# Enable sound with pipewire.
	hardware.pulseaudio.enable = false;
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
		borgbackup
	];

	services.tailscale.enable = true;

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
			"0 3 * * *  daniel  . /etc/profile; /home/daniel/.dotfiles/nixos/backup/backup.sh >> /tmp/backup.log 2>&1"
		];
	};

	virtualisation.oci-containers = {
		backend = "docker";
		containers.homeassistant = {
			volumes = [ "/mnt/data/home-assistant:/config" ];
			environment.TZ = "Europe/Libon";
			image = "ghcr.io/home-assistant/home-assistant:stable"; # Warning: if the tag does not change, the image will not be updated
				extraOptions = [ 
				"--network=host" 
				];
		};

		containers.postgres = {
			image = "postgres:latest";
			autoStart = true;
			ports = [ "5432:5432" ];
			volumes = [ "/mnt/data/postgres:/var/lib/postgresql/data" ];
			environment = {
				POSTGRES_DB = "nextcloud";
				POSTGRES_USER = "nextcloud";
				POSTGRES_PASSWORD = "secret";  # Change to a strong password
			};
		};
		containers.nextcloud = {
			volumes = [
				"/mnt/data/nextcloud:/var/www/html"  # Persist Nextcloud data on your disk
			];
			ports = [ "8080:80" ];  # Map port 80 inside the container to 8080 on the host
			image = "nextcloud:latest"; # Warning: if the tag does not change, the image will not be updated
			autoStart = true;
			environment = {
				NEXTCLOUD_ADMIN_USER = "admin";
				NEXTCLOUD_ADMIN_PASSWORD = "root";
				NEXTCLOUD_TRUSTED_DOMAINS = "100.113.234.108";
				# PostgreSQL auto configuration variables:
				POSTGRES_DB = "nextcloud";
				POSTGRES_USER = "nextcloud";
				POSTGRES_PASSWORD = "secret";
				# Set this to the hostname or IP where the Postgres container is reachable.
				POSTGRES_HOST = "127.0.0.1";  

			};
		};

		containers.paperless = {
			image = "ghcr.io/paperless-ngx/paperless-ngx:latest"; 
			volumes = [
				"/mnt/data/paperless/config:/config"   # Container config
				"/mnt/data/paperless/data:/data"         # Database and metadata storage
				"/mnt/data/paperless/media:/media"       # Storage for your documents
				"/mnt/data/paperless/consume:/consume"   # Directory for documents awaiting processing
			];

			ports = [ "8000:8000" ];  # Map port 80 inside the container to 8080 on the host
			autoStart = true;
		};
	};

	# environment.etc."nextcloud-admin-pass".text = "admin";
	# services.nextcloud = {
	# 	enable = true;
	# 	package = pkgs.nextcloud30;
	# 	hostName = "localhost";
	# 	config.adminpassFile = "/etc/nextcloud-admin-pass";
	# 	config.dbtype = "sqlite";
	# 	settings = {
	# 		trusted_domains = [
	# 			"100.113.234.108"
	# 		];
	# 	};
	# };

	# Some programs need SUID wrappers, can be configured further or are
	# started in user sessions.
	# programs.mtr.enable = true;
	# programs.gnupg.agent = {
	#   enable = true;
	#   enableSSHSupport = true;
	# };

	# List services that you want to enable:

	# Enable the OpenSSH daemon.
	# services.openssh.enable = true;

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
	system.stateVersion = "24.11"; # Did you read the comment?
}
