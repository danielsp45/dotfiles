{ pkgs, ... }:
let
  # Apple's "Apple Color Emoji" repackaged as a COLRv1 font for Linux/fontconfig.
  # Not in nixpkgs (Apple doesn't license it for redistribution), so we fetch the
  # prebuilt TTF from samuelngs/apple-emoji-ttf. Registers as family
  # "Apple Color Emoji" — referenced by fontconfig's emoji default in
  # home/programs/fonts/fonts.nix.
  apple-color-emoji = pkgs.stdenvNoCC.mkDerivation {
    pname = "apple-color-emoji";
    version = "macos-26-20260722";
    src = pkgs.fetchurl {
      url = "https://github.com/samuelngs/apple-emoji-ttf/releases/download/macos-26-20260722-484daf4e/AppleColorEmoji-Linux.ttf";
      hash = "sha256-43x69iZaxKCvbVe8ZehhCad22ZZug0MzRVf2PaSCUW8=";
    };
    dontUnpack = true;
    installPhase = ''
      install -Dm444 $src $out/share/fonts/truetype/AppleColorEmoji.ttf
    '';
  };
in
{
  fonts.packages = with pkgs; [
    apple-color-emoji
    noto-fonts
    font-awesome
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.hack
    nerd-fonts.ubuntu-mono
    nerd-fonts.caskaydia-cove
    nerd-fonts.iosevka
  ];
}
