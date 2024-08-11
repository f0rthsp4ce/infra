{ agenix, home-manager, ... }:

{
  imports = [
    home-manager.nixosModule
    agenix.nixosModules.default

    ./acme.nix
    ./common.nix
    ./dns.nix
    ./nginx-defaults.nix
    ./overlays.nix
    ./ssh.nix
    ./telegram-backup.nix
    ./proxmox-backup.nix
    ./backup-defaults.nix
    ./users.nix
    ./f0runald
  ];
}
