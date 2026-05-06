{ ... }:
let
  nfs = import ../../lib/nfs.nix;
in
{
  fileSystems.${nfs.mountPath} = {
    device = "${nfs.serverAddress}:${nfs.exportPath}";
    fsType = "nfs4";
    options = [ "nfsvers=4.1" "rw" "_netdev" "x-systemd.automount" "x-systemd.idle-timeout=600" ];
  };
}
