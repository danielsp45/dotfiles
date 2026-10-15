{ config, pkgs, ... }:
let
  # Primary user allowed to run `tailscale up/down/set/switch` without sudo.
  operator = "daniel";
in
{
  services.tailscale.enable = true;

  # tailscaled denies prefs writes (up/down/set/switch, and the account list the
  # Quick Settings widget reads) to anyone who is neither root nor the configured
  # operator — hence "Access denied, use sudo". Register the operator once the
  # daemon is up. Idempotent and re-run every boot, so it survives rebuilds and
  # applies on every host that enables this module.
  systemd.services.tailscale-set-operator = {
    description = "Set Tailscale operator to ${operator}";
    after = [ "tailscaled.service" ];
    requires = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # tailscaled may still be bringing its socket up when this fires; retry
      # briefly rather than racing it.
      ExecStart = pkgs.writeShellScript "tailscale-set-operator" ''
        for _ in $(seq 1 30); do
          if ${config.services.tailscale.package}/bin/tailscale set --operator=${operator}; then
            exit 0
          fi
          sleep 1
        done
        echo "tailscale set --operator=${operator} failed after retries" >&2
        exit 1
      '';
    };
  };
}
