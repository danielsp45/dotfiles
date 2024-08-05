{ config, pkgs, ... }:

{
    # Home Manager needs a bit of information about you and the paths it should
    # manage.
    home.username = "danielsp";
    home.homeDirectory = "/home/danielsp";

    imports = [ ./common.nix ];
}
