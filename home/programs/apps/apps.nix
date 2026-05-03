{ pkgs, ... }:
{
  home.packages = with pkgs; [
    vscode
    zed-editor
    notion-app-enhanced
    zotero
    logseq
    obsidian
    discord
    telegram-desktop
    thunderbird
    spotify
    calibre
    gvfs
    zoom
  ];
}
