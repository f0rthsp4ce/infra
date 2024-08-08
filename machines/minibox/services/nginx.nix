{ config, pkgs, self, ... }:

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

  proxy = {
    # Requests coming via the proxy protocol without SSL termination
    listen = [{
      addr = "100.110.43.32";
      port = 8443;
      ssl = true;
      proxyProtocol = true;
    }];
  };
  proxy-extra-config = ''
    # Enable http2
    http2 on;
    # Set the real IP from the proxy protocol
    set_real_ip_from 100.83.232.109;
    real_ip_header proxy_protocol;
    # Set SSL certificates
    ssl_certificate "${
      config.security.acme.certs."f0rth.space".directory
    }/fullchain.pem";
    ssl_certificate_key "${
      config.security.acme.certs."f0rth.space".directory
    }/key.pem";
  '';
in {
  users.users.cloudflared = {
    group = "cloudflared";
    isSystemUser = true;
  };
  users.groups.cloudflared = { };

  age.secrets.credentials-minibox-cloudflared.file =
    "${self}/secrets/credentials/minibox-cloudflared.age";
  systemd.services.cloudflared = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    path = [ pkgs.cloudflared ];
    serviceConfig = {
      ExecStart = pkgs.writeShellScript "cloudflared-service" ''
        cloudflared tunnel run --token=$TOKEN
      '';
      EnvironmentFile = config.age.secrets.credentials-minibox-cloudflared.path;
      Restart = "always";
      User = "cloudflared";
      Group = "cloudflared";
    };
  };

  services.nginx = {
    enable = true;

    virtualHosts."minibox-portainer.lo.f0rth.space" = defaults // {
      locations."/".proxyPass = "https://127.0.0.1:9443";
    };

    virtualHosts."bitwarden.lo.f0rth.space" = defaults // {
      locations."/".proxyPass = "http://127.0.0.1:8222";
    };

    virtualHosts."grafana.lo.f0rth.space" = defaults // {
      locations."/".proxyPass = "http://127.0.0.1:3001";
    };

    virtualHosts."prometheus.lo.f0rth.space" = defaults // {
      locations."/".proxyPass = "http://127.0.0.1:9090";
    };

    virtualHosts."ha.lo.f0rth.space" = defaults // {
      locations."/" = {
        recommendedProxySettings = false;
        proxyPass = "http://ha-direct.lo.f0rth.space:8123";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header        Host $host;
          proxy_set_header        X-Real-IP $remote_addr;
          # Home Assistant doesn't work correctly with the X-Forwarded-Proto header
          # proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header        X-Forwarded-Proto $scheme;
          proxy_set_header        X-Forwarded-Host $host;
          proxy_set_header        X-Forwarded-Server $host;
        '';
      };
    };

    virtualHosts."homeassistant.lo.f0rth.space" = defaults // {
      globalRedirect = "ha.lo.f0rth.space";
    };

    virtualHosts."ldapadmin.lo.f0rth.space" = defaults // {
      locations."/".proxyPass = "https://localhost:6443";
    };

    virtualHosts."enter.f0rth.space" = proxy // {
      locations."/".proxyPass = "http://localhost:9091";
      extraConfig = proxy-extra-config;
    };

    virtualHosts."wiki.f0rth.space" = proxy // {
      locations."/".proxyPass = "http://localhost:3000";
      extraConfig = proxy-extra-config;
    };

    virtualHosts."bitwarden.f0rth.space" = proxy // {
      locations."/".proxyPass = "http://localhost:8222";
      extraConfig = proxy-extra-config;
    };

    virtualHosts."*.secure.f0rth.space" = proxy // {
      # <subdomain>--<port>-<args>.secure.f0rth.space
      # Redirects to <subdomain>.lo.f0rth.space:<port> with optional args
      #
      # Allowed args:
      # - -nph - Do not pass the X-Forwarded-Proto, X-Real-IP, and X-Forwarded-For headers
      # - -h - Use HTTPS instead of HTTP
      # - -nh - Use HTTP instead of HTTPS
      # - -ro - Remove the Origin header
      serverName =
        "~^(?<subdomain>[a-zA-Z0-9-]+?)(--(?<port>\\d+))?(-(?<args>[a-z-]+))?\\.secure\\.f0rth\\.space$";
      # Configure proxy
      extraConfig = ''
        ${proxy-extra-config}

        # Local DNS resolver for dynamic domains
        resolver 127.0.0.1;

        # Include the Authelia snippets
        include ${self}/modules/nginx-snippets/authelia-upstream-minibox.conf;
        include ${self}/modules/nginx-snippets/authelia-location.conf;

        location / {
          # Redirect to hosted domain, if it exists
          if ($subdomain ~* "bitwarden") {
            return 301 https://$subdomain.f0rth.space$request_uri;
          }

          # Fail if the subdomain is not supported
          # set $fail_string "";
          # if ($subdomain ~* "ender3") {
          #   set $fail_string "Ender3 does not support secure proxiyng";
          # }
          # if ($args ~* "-su") {
          #   set $fail_string "";
          # }
          # if ($fail_string) {
          #   return 400 $fail_string;
          # }

          # Include the Authelia authrequest configuration
          include ${self}/modules/nginx-snippets/authelia-authrequest.conf;

          # Set the proxy scheme by mapping of subdomain to overrides
          set $proxy_scheme "http";
          if ($subdomain ~* "ldapadmin|ha|prometheus|grafana|minibox-portainer") {
            set $proxy_scheme "https";
          }
          # If the -nh flag is specified, set the scheme to http
          if ($args ~* "-nh") {
            set $proxy_scheme http;
          }
          # If the -h flag is specified, set the scheme to https
          if ($args ~* "-h") {
            set $proxy_scheme https;
          }

          # Set the port by mapping of subdomain to port overrides
          set $proxy_port "";
          if ($subdomain ~* "ha-direct") {
            set $proxy_port ":8123";
          }
          # If the port is specified, set it
          if ($port) {
            set $proxy_port ":$port";
          }

          # Constuct the proxy URLs
          set $proxy "$proxy_scheme://$subdomain.lo.f0rth.space$proxy_port";
          set $domain "$subdomain.lo.f0rth.space";

          # Set the Host header to the domain
          proxy_set_header Host $domain;

          # Prepare optional headers
          set $modified_proxy_add_x_forwarded_for $proxy_add_x_forwarded_for;
          set $modified_scheme $scheme;
          set $modified_remote_addr $remote_addr;

          # Remove proxy headers by mapping of subdomain to overrides
          set $nph false;
          if ($subdomain ~* "ha-direct") {
            set $nph true;
          }
          # If the -nph flag is specified, remove the headers
          if ($args ~* "-nph") {
            set $nph true;
          }
          if ($nph) {
            set $modified_proxy_add_x_forwarded_for "";
            set $modified_scheme "";
            set $modified_remote_addr "";
          }

          # Add optional headers
          proxy_set_header X-Forwarded-For $modified_proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $modified_scheme;
          proxy_set_header X-Real-IP $modified_remote_addr;

          # Remove origin header from request
          set $remove_origin false;
          if ($subdomain ~* "ender3") {
            set $remove_origin true;
          }
          if ($args ~* "-ro") {
            set $remove_origin true;
          }
          set $remove_origin_content "";
          if ($remove_origin = false) {
            set $remove_origin_content $http_origin;
          }
          proxy_set_header Origin $remove_origin_content;

          # Add debug headers
          add_header X-Proxy-Host $domain;
          add_header X-Proxy-Port $proxy_port;
          add_header X-Proxy-Scheme $proxy_scheme;
          add_header X-Proxy-Subdomain $subdomain;
          add_header X-Proxy-Args $args;
          add_header X-Proxy-NPH $nph;
          add_header X-Proxy-Remove-Origin $remove_origin;

          # Allow the use of WebSockets
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
          proxy_read_timeout 86400;

          # Disable compression
          proxy_set_header Accept-Encoding "";

          # Replace host in response to the domain
          sub_filter_once off;
          sub_filter $domain $host;

          # Proxy the request to the target
          proxy_pass $proxy;
        }
      '';
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 80 443 ];
    allowedUDPPorts = [ 443 ];
  };
  # Allow requests to proxy protocol listen from proxy
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 8443 ];
}
