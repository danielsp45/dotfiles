{
  serverAddress = "100.81.92.40";
  exportPath = "/storage";
  mountPath = "/mnt/nas";
  # Tailscale CGNAT range — restrict further (e.g. to your LAN) if needed
  allowedNetwork = "100.64.0.0/10";
}
