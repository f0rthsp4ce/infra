{ config, ... }:

let
  defaults = {
    quic = true;
    http3 = true;
    kTLS = true;
    forceSSL = true;
    sslCertificate =
      "${config.security.acme.certs."f0rth.space".directory}/fullchain.pem";
    sslCertificateKey =
      "${config.security.acme.certs."f0rth.space".directory}/key.pem";
  };
in {
  services.nginx = {
    enable = true;

    virtualHosts."minibox-portainer.lo.f0rth.space" = defaults // {
      locations."/".proxyPass = "https://127.0.0.1:9443";
    };

    virtualHosts."bitwarden.lo.f0rth.space" = defaults // {
      locations."/".return = "https://bitwarden.f0rth.space:1337$request_uri";
    };

    virtualHosts."bitwarden.f0rth.space" = defaults // {
      listen = [{
        addr = "0.0.0.0";
        port = 1337;
        ssl = true;
      }];
      locations."/".proxyPass = "http://127.0.0.1:8222/";
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 80 443 1337 ];
    allowedUDPPorts = [ 443 1337 ];
  };
}
