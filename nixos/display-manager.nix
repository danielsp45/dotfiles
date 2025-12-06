{ config, pkgs, lib, ... }:

{
	services.displayManager.ly.enable = true;
	services.displayManager.sddm.wayland.enable = true;
  programs.hyprland.enable = true;
	programs.xwayland.enable = true;
	# Optional, hint electron apps to use wayland:
	environment.sessionVariables = {
		NIXOS_OZONE_WL = "1";
		CLUTTER_BACKEND = "wayland";
		SDL_VIDEODRIVER = "wayland";
		QT_QPA_PLATFORM = "wayland";
		GDK_BACKEND = "wayland";
	};
}
