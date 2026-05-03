{ ... }:
{
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PubkeyAuthentication = true;
      AllowUsers = null;
      UseDns = true;
      PermitRootLogin = "prohibit-password";
      X11Forwarding = true;
      X11DisplayOffset = 10;
      X11UseLocalHost = true;
      AllowAgentForwarding = "yes";
    };
  };
}
