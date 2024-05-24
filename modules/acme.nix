{ self, config, lib, ... }:

{
  config = lib.mkIf (config.security.acme.certs != { }) {
    age.secrets.credentials-cloudflare.file =
      "${self}/secrets/credentials/cloudflare.age";

    security.acme = {
      acceptTerms = true;
      defaults = {
        email = "admin@f0rth.space";
        dnsProvider = "cloudflare";
        credentialsFile = config.age.secrets.credentials-cloudflare.path;
      };
    };
  };
}
