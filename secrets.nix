let
  user-keys = import ./ssh-keys.nix;

  users = user-keys.cofob ++ user-keys.dettlaff ++ user-keys.tar-xzf
    ++ user-keys.mike;

  minibox =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDCGY+yafid8DBeWFwXO5q/aSCgLvv726NKEO3KJeThC";
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
  "secrets/credentials/vaultwarden.age".publicKeys = users ++ [ minibox ];
}
