{ pkgs, ... }:
{
  home.packages = with pkgs; [
    typst
    roboto
    source-sans-pro
  ];

  # Only the monospace generic (terminals/code) is pinned to JetBrainsMono Nerd
  # Font. The UI families (sans-serif/serif) are intentionally left unset so they
  # keep the system default, as they were originally.
  fonts.fontconfig.defaultFonts = {
    monospace = [ "JetBrainsMono Nerd Font" ];
    emoji = [ "Apple Color Emoji" "Noto Color Emoji" ];
  };
}
