{ pkgs, ... }:
{
  home.packages = with pkgs; [
    _1password-cli
    _1password-gui
    ansible
    devcontainer
    flamegraph
    gparted
    networkmanager
    networkmanager-openvpn
    btrfs-progs
    jq
    quickemu
    quickgui
    virt-manager
    libimobiledevice
    ifuse
    nwg-displays
    nextcloud-client
    protonmail-desktop
    proton-vpn
    google-chrome
    chromium
    caddy
    ledger-live-desktop
    xclip
    wl-clipboard
    localsend
    nemo
    adw-gtk3
    papirus-icon-theme
    hicolor-icon-theme
    kdePackages.okular
    mpv
    iptvnator
  ];

  xdg.configFile."mpv/mpv.conf".text = ''
    cache=yes
    cache-secs=30
    demuxer-max-bytes=50MiB
    demuxer-max-back-bytes=25MiB

    # Ask the compositor for the video's own colourspace, not the display's best.
    # Stops Hyprland (cm_auto_hdr) switching to HDR for SDR streams in fullscreen.
    target-colorspace-hint-mode=source

    # IPTV is mostly 1080i at a few Mbps: deinterlace when the stream is
    # interlaced (25i -> 50p), upscale to 1440p with a better scaler, and
    # smooth out banding from heavy compression.
    deinterlace=auto
    profile=high-quality
    deband=yes
  '';
}
