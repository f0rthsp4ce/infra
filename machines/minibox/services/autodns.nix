{ self, config, pkgs, ... }:

{
  age.secrets.credentials-autodns-cloudflare.file =
    "${self}/secrets/credentials/autodns-cloudflare.age";

  users.users.autodns-cloudflare = {
    isSystemUser = true;
    group = "autodns-cloudflare";
  };
  users.groups.autodns-cloudflare = { };

  systemd.services.autodns-cloudflare = {
    description = "DNS hostnames for Cloudflare";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    environment.PYTHONUNBUFFERED = "1";
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.autodns}/bin/autodns";
      Restart = "always";
      RestartSec = "5";
      User = "autodns-cloudflare";
      Group = "autodns-cloudflare";
      EnvironmentFile = config.age.secrets.credentials-autodns-cloudflare.path;
    };
  };
}
