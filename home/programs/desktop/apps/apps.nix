{ pkgs, ... }:
{
  home.packages = with pkgs; [
    vscode
    zed-editor
    notion-app-enhanced
    zotero
    obsidian
    discord
    telegram-desktop
    thunderbird
    spotify
    calibre
    gvfs
    jellyfin
  ];
}
