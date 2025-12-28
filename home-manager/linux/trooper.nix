{ config, pkgs, lib, ... }:

let
  # Where your dotfiles live on disk (change if needed)
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  oos = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";

in {
    # Home Manager needs a bit of information about you and the paths it should
    # manage.
    home.username = "daniel";
	  home.homeDirectory = lib.mkForce "/home/daniel";

    home.file = {
        ".zshrc".source = oos "zsh/linux/zshrc";
        ".config/ghostty".source = oos "ghostty";
        ".config/hypr".source = oos "hypr";
        ".config/waybar".source = oos "waybar";
        ".config/rofi".source = oos "rofi";
        ".config/dunst".source = oos "dunst";
        ".config/swayosd".source = oos "swayosd";
        ".config/walker".source = oos "walker";
        ".config/quickshell".source = oos "quickshell";
        ".local/share/config/bin".source = oos "bin";
    };

	home.packages = with pkgs; [
		# password managers
		_1password-cli
		_1password-gui

		# development tools
		vscode
    tlaplus
    tlaplusToolbox
    # jdk11
    jdk21
    cmake

		# system utilities
		gparted
		networkmanager
		networkmanager-openvpn
		btrfs-progs
		via
		amdgpu_top
		fastfetch
		ghostty
    jq
    quickemu
    quickgui
    libimobiledevice
    ifuse
    nwg-displays
    nextcloud-client
    lm_sensors
    cifs-utils

		# web & networking
		google-chrome
    chromium
		caddy
    ledger-live-desktop

		# clipboard
		xclip
		wl-clipboard

		# productivity
		nemo
		notion-app-enhanced
		zotero
	  logseq
    obsidian
    localsend
    libreoffice

		# communication
		discord
		telegram-desktop
		thunderbird

		# multimedia
		spotify
    # stremio # dependes on qtwebengine which is not in a safe version
    zoom
    localsend

    # kindle stuff
    calibre
    gvfs

		# gaming & launchers
		lutris
		prismlauncher
		heroic
		wine

		# theming
		adw-gtk3
		papirus-icon-theme

		# wayland & screen tools
    walker
		waybar
		swaybg
		swaylock
		wayidle
		waypaper
		grim
		hyprshot
    satty
    slurp
    libnotify
    wf-recorder
    wl-screenrec
    ffmpeg
    hyprpicker
    hypridle
    quickshell
    hyprsunset
    hyprlock

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

  services.swayosd = {
    enable = true;
  };



	programs.starship.enable = true;

  imports = [ ./../common.nix ];
}
