{
  lib,
  appimageTools,
  fetchurl,
}:

let
  version = "0.23.0";
  src = fetchurl {
    url = "https://github.com/4gray/iptvnator/releases/download/v${version}/iptvnator-${version}-linux-x86_64.AppImage";
    hash = "sha256-PB0DEtk9o8x1kFsLkeep0MllyMUhbYuDhr7C/sqTGdI=";
  };
in
appimageTools.wrapType2 {
  pname = "iptvnator";
  inherit version src;

  meta = {
    description = "IPTV player and list manager";
    homepage = "https://github.com/4gray/iptvnator";
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "iptvnator";
  };
}
