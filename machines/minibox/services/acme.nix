{ config, ... }:

{
  security.acme.certs."f0rth.space" = {
    extraDomainNames = [ "*.f0rth.space" "*.lo.f0rth.space" "*.secure.f0rth.space" ];
    group = config.services.nginx.group;
  };
}
