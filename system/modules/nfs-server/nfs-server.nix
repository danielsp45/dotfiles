{ ... }:
let
  nfs = import ../../lib/nfs.nix;
in
{
  services.nfs.server = {
    enable = true;
    exports = ''
      /              ${nfs.allowedNetwork}(ro,fsid=0,no_subtree_check)
      ${nfs.exportPath} ${nfs.allowedNetwork}(rw,sync,no_subtree_check,no_root_squash)
    '';
  };

  networking.firewall.allowedTCPPorts = [ 2049 ];
  networking.firewall.allowedUDPPorts = [ 2049 ];
}
