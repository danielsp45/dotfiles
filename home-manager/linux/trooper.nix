{ config, pkgs, lib, ... }:

{
    # Home Manager needs a bit of information about you and the paths it should
    # manage.
    home.username = "daniel";
	home.homeDirectory = lib.mkForce "/home/daniel";

    home.file = {
        ".zshrc".source = ./../../zsh/linux/zshrc;
        ".gitconfig".source = ./../../git/gitconfig;
        ".config/ghostty".source = ./../../ghostty;
        ".config/hypr".source = ./../../hypr;
        ".config/waybar".source = ./../../waybar;
        ".config/rofi".source = ./../../rofi;
        ".config/dunst".source = ./../../dunst;
    };

	home.packages = with pkgs; [
		# password managers
		_1password-cli
		_1password-gui

		# development tools
		cmake
		gnumake
		nodejs_23
		starship
		thefuck
		fzf
		vscode
		direnv

		# system utilities
		gparted
		networkmanager
		networkmanager-openvpn
		btrfs-progs
		via
		amdgpu_top
		fastfetch
		ghostty

		# web & networking
		google-chrome
		caddy

		# clipboard
		xclip
		wl-clipboard

		# productivity
		nemo
		notion-app-enhanced
		zotero

		# communication
		discord
		telegram-desktop
		thunderbird

		# multimedia
		spotify

		# gaming & launchers
		prismlauncher

		# theming
		adw-gtk3
		papirus-icon-theme
		lxappearance

		# wayland & screen tools
		rofi-wayland
		waybar
		swaybg
		swaylock
		wayidle
		waypaper
		grim
		hyprshot

		# cursor theme
		rose-pine-hyprcursor

		# GPU packages
		rocmPackages.rpp
	];

	gtk = {
		enable = true;
		theme.name = "Adw-gtk3";
		iconTheme.name = "Papirus";
		cursorTheme = {
			name = "rose-pine-hyprcursor";  # Change the name
			size = 24;
		};
	};

	programs.direnv = {
		enable = true;
		nix-direnv.enable = true; # Highly recommended for faster Nix integration
		# This automatically includes the 'use nix' directive for .envrc files
		# and optimizes 'nix develop' integration with direnv.
	};


	programs.starship.enable = true;

    imports = [ ./../common.nix ];
}
