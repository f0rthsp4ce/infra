{ config, pkgs, ... }:

{
  services.postgresql = {
    enable = true;

    ensureUsers = [
      {
        name = "dendrite";
        ensureDBOwnership = true;
      }
      {
        name = "mautrix-telegram";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [ "dendrite" "mautrix-telegram" ];
  };

  services.postgresqlBackup = {
    enable = true;
    compression = "none";
    backupAll = true;
  };

  services.proxmox-backup.jobs.daily.paths = [
    {
      name = "postgresql";
      path = config.services.postgresql.dataDir;
    }
    {
      name = "postgresql_backup";
      path = config.services.postgresqlBackup.location;
    }
  ];
  services.telegram-backup.timers.daily = [
    config.services.postgresql.dataDir
    config.services.postgresqlBackup.location
  ];
}
