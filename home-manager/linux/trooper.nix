{ config, pkgs, lib, ... }:

{
    # Home Manager needs a bit of information about you and the paths it should
    # manage.
    home.username = "daniel";
	home.homeDirectory = lib.mkForce "/home/daniel";

    home.file = {
        ".zshrc".source = ./../../zsh/linux/zshrc;
        ".config/ghostty".source = ./../../ghostty;
        ".config/hypr".source = ./../../hypr;
        ".config/waybar".source = ./../../waybar;
        ".config/rofi".source = ./../../rofi;
    };

    home.packages = with pkgs; [
        _1password-cli
        _1password-gui
		btrfs-progs
		nodejs_23
		starship
		caddy
		ghostty
		discord
		spotify
		notion-app-enhanced
		telegram-desktop
		cmake
		libgcc
		gnumake
		xclip
		amdgpu_top
		vscode
		prismlauncher
		rocmPackages.rpp
		fastfetch
		rofi-wayland
		waybar
		waypaper
		swaybg
		swaylock
		wayidle 
		rose-pine-hyprcursor
		zotero
		nemo
		adw-gtk3
		papirus-icon-theme
		lxappearance
		xdg-desktop-portal
		grim
		hyprshot
		thunderbird
		thefuck
		fzf
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

	programs.starship.enable = true;

    imports = [ ./../common.nix ];
}
