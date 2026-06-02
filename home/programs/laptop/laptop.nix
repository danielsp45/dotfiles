{ pkgs, ... }:
{
  home.packages = with pkgs; [
    sshfs
    mutagen
    via
    yt-dlp
    mpv
  ];
}
