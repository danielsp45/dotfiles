{ config, pkgs, ... }:

{
    # Home Manager needs a bit of information about you and the paths it should
    # manage.
    home.username = "daniel";
    home.homeDirectory = "/Users/daniel";

    home.file = {
        ".zshrc".source = ./../../zsh/darwin/zshrc;
        ".config/alacritty".source = ./../../alacritty;
        ".config/aerospace".source = ./../../aerospace;
        ".config/zellij".source = ./../../zellij;
    };

    home.packages = [
        pkgs.zellij
        pkgs.gh
        pkgs.fzf
    ];


    imports = [ ./../common.nix ];
}
