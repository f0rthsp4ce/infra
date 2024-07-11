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
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };
  networking.firewall.extraCommands = ''
    iptables -t nat -A POSTROUTING -o enp1s0 -j MASQUERADE
  '';

  networking.firewall.allowedTCPPorts = [
    22 # ssh
  ];

  networking = {
    hostName = "minibox";
    networkmanager.enable = true;
  };
}
