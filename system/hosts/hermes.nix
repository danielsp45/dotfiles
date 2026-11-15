{ config, pkgs, ... }:
{
  dotfiles.modules.audio.enable = true;
  dotfiles.modules.networking.enable = true;
  dotfiles.modules.fonts.enable = true;
  dotfiles.modules.display-manager.enable = true;
  dotfiles.modules.internationalisation.enable = true;
  dotfiles.modules.printing.enable = true;
  dotfiles.modules.bluetooth.enable = true;
  dotfiles.modules.docker.enable = true;
  dotfiles.modules.tailscale.enable = true;
  dotfiles.modules.openssh.enable = true;
  dotfiles.modules.flatpak.enable = true;
  dotfiles.modules.firefox.enable = true;
  dotfiles.modules.syncthing.enable = true;
  dotfiles.modules.programs.enable = true;
  dotfiles.modules.nfs-client.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # T2 Mac: nixos-hardware.nixosModules.apple-t2 + the patched kernel are
  # wired up in flake.nix (extraModules), since they need the flake's
  # nixos-hardware input in scope.
  hardware.apple-t2.kernelChannel = "stable";

  # Touch Bar: tiny-dfr draws the media/function rows (via appletbdrm) and
  # switches to F1–F12 while Fn is held. Without it only the kernel's basic
  # hid-appletb-kbd fallback is active.
  hardware.apple.touchBar = {
    enable = true;
    settings = {
      MediaLayerDefault = true; # brightness/volume/media by default, Fn → F-keys
      ShowButtonOutlines = true;
      EnablePixelShift = true; # avoid burn-in
    };
  };

  # The T2 exposes the built-in trackpad over its internal USB bus, so udev
  # tags it as an *external* touchpad. libinput then skips disable-while-typing
  # and keyboard-aware palm rejection, and palm brushes register as taps.
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="event*", ENV{ID_INPUT_TOUCHPAD}=="1", ATTRS{name}=="Apple Inc. Apple Internal Keyboard / Trackpad", ENV{ID_INPUT_TOUCHPAD_INTEGRATION}="internal", ENV{ID_INTEGRATION}="internal"
  '';

  # Lid close / suspend uses s2idle ("light" sleep) instead of S3 deep sleep:
  # wakes almost instantly, at the cost of somewhat higher battery drain.
  boot.kernelParams = [ "mem_sleep_default=s2idle" ];

  # The T2 drops and re-adds its internal USB devices across suspend. The Touch
  # Bar drivers then re-probe in the wrong order (keys before backlight, display
  # never binds), tiny-dfr's udev rule can leave the Touch Bar unconfigured
  # (it must be in USB configuration 2, "display mode"), and tiny-dfr dies.
  # Unload the drivers before sleep; on resume reload them in order, put the
  # Touch Bar back into configuration 2 and restart tiny-dfr.
  systemd.services.t2-touchbar-sleep = let
    modprobe = "${pkgs.kmod}/bin/modprobe";
    systemctl = "${config.systemd.package}/bin/systemctl";
    touchbarDisplayMode = pkgs.writeShellScript "touchbar-display-mode" ''
      for d in /sys/bus/usb/devices/*; do
        [ "$(cat "$d/idVendor" 2>/dev/null)" = 05ac ] || continue
        [ "$(cat "$d/idProduct" 2>/dev/null)" = 8302 ] || continue
        [ "$(cat "$d/bConfigurationValue")" = 2 ] || echo 2 > "$d/bConfigurationValue"
      done
    '';
  in {
    description = "Reset T2 Touch Bar drivers around suspend";
    before = [ "sleep.target" ];
    wantedBy = [ "sleep.target" ];
    unitConfig.StopWhenUnneeded = true;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = [
        "-${systemctl} stop tiny-dfr.service"
        "-${modprobe} -r appletbdrm hid_appletb_kbd hid_appletb_bl"
      ];
      ExecStop = [
        "${modprobe} hid_appletb_bl"
        "${modprobe} hid_appletb_kbd"
        "${modprobe} appletbdrm"
        "-${touchbarDisplayMode}"
        "-${systemctl} reset-failed tiny-dfr.service"
        "-${systemctl} --no-block restart tiny-dfr.service"
      ];
    };
  };

  # Power button: short press locks the screen.
  # Apple's firmware sends a power-button ACPI notification that the regular
  # `button` driver ignores (no KEY_POWER ever reaches logind/Hyprland). The only
  # driver that reacts is `tiny_power_button`, which signals systemd (PID 1)
  # directly — by default with SIGRTMIN+4 = instant poweroff. Make it send
  # SIGPWR instead: systemd then just starts sigpwr.target, which we hook to
  # lock the screen. Holding the button still forces a hardware power-off.
  boot.extraModprobeConfig = ''
    options tiny_power_button power_signal=30
  '';
  systemd.services.power-button-lock = {
    description = "Lock the screen on a power-button press";
    wantedBy = [ "sigpwr.target" ];
    serviceConfig = {
      Type = "oneshot";
      # sigpwr.target stays active after starting; stop it so the next press
      # triggers again.
      ExecStartPost = "${pkgs.systemd}/bin/systemctl stop --no-block sigpwr.target";
    };
    path = [ pkgs.coreutils pkgs.util-linux config.programs.hyprland.package ];
    script = ''
      # Ask every running Hyprland instance to run the user's lock-screen script.
      for dir in /run/user/*/hypr/*/; do
        [ -S "$dir/.socket.sock" ] || continue
        uid=$(stat -c %u "$dir")
        runuser -u "$(id -nu "$uid")" -- env \
          XDG_RUNTIME_DIR="/run/user/$uid" \
          HYPRLAND_INSTANCE_SIGNATURE="$(basename "$dir")" \
          hyprctl eval 'hl.exec_cmd("~/.local/share/config/bin/lock-screen")' || true
      done
    '';
  };

  # Wi-Fi and Bluetooth firmware for T2 Macs
  hardware.firmware = [ (pkgs.stdenvNoCC.mkDerivation {
    name = "brcm-firmware";
    src = ./hermes/firmware/brcm;
    installPhase = ''
      mkdir -p $out/lib/firmware/brcm
      cp -r * $out/lib/firmware/brcm/
    '';
  }) ];

  users.users.daniel.extraGroups = [
    "networkmanager" "wheel" "input" "daniel" "docker"
  ];
}
