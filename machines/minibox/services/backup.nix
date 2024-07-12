{ config, self, ... }:

{
  age.secrets.credentials-proxmox-backup-key.file =
    "${self}/secrets/credentials/proxmox-backup/key.age";
  age.secrets.credentials-proxmox-backup-env.file =
    "${self}/secrets/credentials/proxmox-backup/env.age";
  services.proxmox-backup = {
    enable = true;
    fingerprint =
      "b6:58:13:55:b5:73:b4:ff:8f:3c:f0:c6:2e:ee:0d:3c:dc:41:18:c8:6f:2b:6b:32:f3:3a:0c:23:09:f6:05:b9";
    namespace = "f0rthsp4ce";
    keyFile = config.age.secrets.credentials-proxmox-backup-key.path;
    envFile = config.age.secrets.credentials-proxmox-backup-env.path;
  };

  age.secrets.credentials-telegram-backup.file =
    "${self}/secrets/credentials/telegram-backup.age";
  services.telegram-backup = {
    enable = true;
    envFile = config.age.secrets.credentials-telegram-backup.path;
    gpgKeys = [ "04EEF0BA3B857B065A326067341A36929AC4AC29" ];
  };
}
