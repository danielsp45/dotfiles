{ config, pkgs, lib, zen-browser, ... }:

{
	programs.zsh.enable = true;

	# Install firefox.
	programs.firefox.enable = true;

	# Allow unfree packages
	nixpkgs.config.allowUnfree = true;

	# List packages installed in system profile. To search, run:
	# $ nix search wget
	environment.systemPackages = with pkgs; [
		vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
		tmux
		wget
		neofetch
		git
		openrgb-with-all-plugins
		xorg.xinit
		pciutils
		arandr
		blueman
		pulseaudio
		playerctl
		dunst
		ly
		networkmanagerapplet
		docker
		docker-compose      # if you want docker-compose
		wl-clipboard
		zen-browser.packages.${pkgs.system}.default
		pavucontrol
    uwsm
    sbctl
    networkmanager-openvpn
	];

	virtualisation.docker.enable = true;

	programs.dconf.enable = true;

	services.tailscale.enable = true;

	services.hardware.openrgb.enable = true;

	services.flatpak.enable = true;

	hardware.bluetooth.enable = true; # enables support for bluetooth
	hardware.bluetooth.powerOnBoot = true;
  hardware.bluetooth.settings = {
    General = {
      Enable = "Source,Sink,Media,Socket";
      Experimental = true;
    };
  };

  hardware.steam-hardware.enable = true;
	programs.steam = {
		enable = true;
		remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
		dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
		localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
	};

	programs.nix-ld.enable = true;

	services.openssh = {
		enable = true;
		ports = [ 22 ];
		settings = {
			# PasswordAuthentication = true;
      PubkeyAuthentication = true;
			AllowUsers = null; # Allows all users by default. Can be [ "user1" "user2" ]
			UseDns = true;
			PermitRootLogin = "prohibit-password"; # "yes", "without-password", "prohibit-password", "forced-commands-only", "no"
			X11Forwarding = true;
			X11DisplayOffset = 10; # Good practice
			X11UseLocalHost = true; # Also good practice
      AllowAgentForwarding = "yes";
		};
	};
}
