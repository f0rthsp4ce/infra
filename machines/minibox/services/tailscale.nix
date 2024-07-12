{ ... }:

{
  services.tailscale.enable = true;
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };
  networking.firewall.extraCommands = ''
    iptables -t nat -A POSTROUTING -o enp1s0 -j MASQUERADE
  '';
}
