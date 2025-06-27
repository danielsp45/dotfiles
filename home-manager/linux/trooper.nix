{ config, pkgs, lib, ... }:

{
    # Home Manager needs a bit of information about you and the paths it should
    # manage.
    home.username = "daniel";
	home.homeDirectory = lib.mkForce "/home/daniel";

    home.file = {
        ".zshrc".source = ./../../zsh/linux/zshrc;
        ".config/ghostty".source = ./../../ghostty;
        # ".config/bspwm/bspwmrc".source = ./../../bspwm/bspwmrc;
        # ".config/sxhkd/sxhkdrc".source = ./../../bspwm/sxhkdrc;
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
		capitaine-cursors
		zotero
		nemo
		adw-gtk3
		papirus-icon-theme
		lxappearance
		xdg-desktop-portal
		grim
		hyprshot
		thunderbird
    ];

	gtk = {
	  enable = true;
	  theme.name = "Adw-gtk3";
	  iconTheme.name = "Papirus";
	  cursorTheme.name = "Bibata-Modern-Classic";
	};

	home.sessionVariables = {
		USE_WAYLAND_GRIM = "1";
	};

    programs = {
        zsh = {
            enable = true;
            shellAliases = {
                # General
                cat="bat";
                nv="nvim";
                lv="lvim";
                v="nvim $(fzf)";
                ":q"="exit";
                cl="clear";

                # Scripts
                bs="bin/server";
                bb="bin/build";
                br="bin/run";
                bt="bin/test";
                bf="bin/format";
                bl="bin/lint";
                bsh="bin/console";
                bcl="bin/clean";
                bst="bin/setup";
                bsr="bin/start";
                bsp="bin/stop";
                    
                # Elixir mix
                m="mix";
                im="iex -S mix";
                ms="mix phx.server";
                mc="mix do clean, compile";
                mf="mix format";
                ml="mix lint";
                mt="mix test";
                mpr="mix phx.routes";
                mer="mix ecto.reset";

                # Make
                mk="make";
                mkh="make help";
                mkl="make lint";
                mkc="make clean";
                mkr="make run";
                mkt="make test";
                mkut="make unit-tests";
                mkts="make tests";
            };

            oh-my-zsh = {
                enable = true;
                theme = "cloud";
                plugins = [
                    "git"
                    "history"
                    "zsh-z"
                    "asdf"
                    "docker-compose"
                    "extract"
                    "fzf-tab"
                ];
            };
        };
    };

    imports = [ ./../common.nix ];
}
