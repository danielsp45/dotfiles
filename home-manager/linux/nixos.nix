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
