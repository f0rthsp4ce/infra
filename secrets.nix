let
  user-keys = import ./ssh-keys.nix;

  users = user-keys.cofob ++ user-keys.dettlaff ++ user-keys.tar-xzf
    ++ user-keys.mike;

  minibox =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDCGY+yafid8DBeWFwXO5q/aSCgLvv726NKEO3KJeThC";
  vmbox =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOo7kizbOeCwa9smjSmkj4+nAfEJVun9b5T/MQ35zVF1";
  systems = [ minibox ];

  all = users ++ systems;
in {
  # User passwords
  "secrets/passwords/root.age".publicKeys = all;
  "secrets/passwords/cofob.age".publicKeys = all;
  "secrets/passwords/def.age".publicKeys = all;
  "secrets/passwords/tar.age".publicKeys = all;
  "secrets/passwords/mike.age".publicKeys = all;

  # Services
  "secrets/credentials/cloudflare.age".publicKeys = users ++ [ minibox ];
  "secrets/credentials/telegram-backup.age".publicKeys = all;
  "secrets/credentials/proxmox-backup/env.age".publicKeys = all;
  "secrets/credentials/proxmox-backup/key.age".publicKeys = all;
  "secrets/credentials/vaultwarden.age".publicKeys = users ++ [ minibox ];
  "secrets/credentials/minibox-cloudflared.age".publicKeys = users
    ++ [ minibox ];
  "secrets/credentials/f0runald.age".publicKeys = users ++ [ vmbox ];
  "secrets/credentials/botka-v0.age".publicKeys = users ++ [ vmbox ];
  "secrets/credentials/botka-v1.age".publicKeys = users ++ [ vmbox ];
}
