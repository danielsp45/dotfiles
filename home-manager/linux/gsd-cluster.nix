{ config, pkgs, ... }:

{
    # Home Manager needs a bit of information about you and the paths it should
    # manage.
    home.username = "gsd";
    home.homeDirectory = "/home/gsd";

    imports = [ ./../common.nix ];

    programs = {
        zsh = {
            enable = true;
            autosuggestions.enable = true;
            zsh-autoenv.enable = true;
            syntaxHighlighting.enable = true;
            ohMyZsh = {
                enable = true;
                theme = "robbyrussell";
                plugins = [
                    "git"
                    "docker"
                    "docker-compose"
                    "extract"
                    "fzf-tab"
                    "autoswitch_virtualenv"
                    "zsh-c"
                ];
            };
        };
    };
}
