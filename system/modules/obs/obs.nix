{ pkgs, config, ... }:
{
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  boot.extraModprobeConfig = ''
    options v4l2loopback exclusive_caps=1 devices=1 video_nr=0 card_label="OBS Cam"
  '';

  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      droidcam-obs
      obs-backgroundremoval
    ];
  };

  environment.systemPackages = [ pkgs.v4l-utils ];
}
