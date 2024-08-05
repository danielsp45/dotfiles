{ config, pkgs, ... }:

{
    # Home Manager needs a bit of information about you and the paths it should
    # manage.
    home.username = "gsd";
    home.homeDirectory = "/home/gsd";

    imports = [ ./../common.nix ];
}
