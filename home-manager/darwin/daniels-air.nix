{ config, pkgs, ... }:

{
    # Home Manager needs a bit of information about you and the paths it should
    # manage.
    home.username = "danielsp_45";
    home.homeDirectory = "/Users/danielsp_45";

    home.file = {
        ".zshrc".source = ./../../zsh/darwin/zshrc;
        ".config/alacritty".source = ./../../alacritty;
        ".config/aerospace".source = ./../../aerospace;
        ".config/zellij".source = ./../../zellij;
    };

    home.packages = [
        pkgs.zellij
        pkgs.gh
    ];

    imports = [ ./../common.nix ];
}
