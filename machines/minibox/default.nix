{ self, config, ... }:

{
  imports = [
    ./services

    "${self}/modules"
    "${self}/hardware/minibox.nix"
  ];

  security.acme.certs."f0rth.space" = {
    extraDomainNames = [ "*.f0rth.space" "*.lo.f0rth.space" ];
    group = config.services.nginx.group;
  };

  virtualisation.docker.enable = true;

  services.telegram-backup.enable = true;

  services.tailscale.enable = true;

  networking.firewall.allowedTCPPorts = [
    22 # ssh
  ];

  networking = {
    hostName = "minibox";
    networkmanager.enable = true;
  };
}
