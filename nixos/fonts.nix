{ config, pkgs, lib, ... }:

{
	fonts.packages = with pkgs; [ 
		noto-fonts 
		font-awesome
		nerd-fonts.jetbrains-mono
		nerd-fonts.fira-code
		nerd-fonts.jetbrains-mono
		nerd-fonts.hack
		nerd-fonts.ubuntu-mono
		nerd-fonts.caskaydia-cove
    nerd-fonts.iosevka
	];
}
