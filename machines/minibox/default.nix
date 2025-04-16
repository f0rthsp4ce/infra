{ self, config, ... }:

{
  imports = [
    ./services

    "${self}/modules"
    "${self}/hardware/minibox.nix"
  ];

  custom.backup-defaults.enable = true;

  services.cloudflared.enable = true;

  networking.firewall.allowedTCPPorts = [
    22 # ssh
  ];

  networking = {
    hostName = "minibox";
    networkmanager.enable = true;
  };
}
