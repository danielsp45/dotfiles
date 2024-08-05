{ config, pkgs, ... }:

{
    # Home Manager needs a bit of information about you and the paths it should
    # manage.
    home.username = "danielsp_45";
    home.homeDirectory = "/Users/danielsp_45";

    home.file = {
    ".config/yabai".source = ./../../yabai;
    ".config/skhd".source = ./../../skhd;
    };

    imports = [ ./../common.nix ];
}
