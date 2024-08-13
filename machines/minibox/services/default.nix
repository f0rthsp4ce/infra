{ ... }:

{
  imports = [
    ./acme.nix
    ./bw.nix
    ./docker.nix
    ./nginx.nix
    ./portainer.nix
    ./tailscale.nix
    ./dyndns.nix
    ./autodns.nix
    ./uptime.nix
    ./matrix.nix
    ./db.nix
  ];
}
