{ config, pkgs, lib, ... }:

{
    # Home Manager needs a bit of information about you and the paths it should
    # manage.
    home.username = "daniel";
	home.homeDirectory = lib.mkForce "/home/daniel";

    home.file = {
        ".zshrc".source = ./../../zsh/linux/zshrc;
        ".gitconfig".source = ./../../git/gitconfig;
    };

    home.packages = [
        pkgs._1password-cli
        pkgs._1password-gui
		pkgs.btrfs-progs
		pkgs.starship
		pkgs.caddy
		pkgs.cloudflared
		pkgs.ghostty
    ];

	programs.starship.enable = true;

    imports = [ ./../common.nix ];
}
