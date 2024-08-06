{ lib, config, pkgs, ... }:

with lib;

let cfg = config.services.proxmox-backup;
in {
  options = {
    services.proxmox-backup = {
      enable = mkEnableOption "Whether to enable proxmox-backup-client backups";

      environment = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Default service environment variables";
      };

      envFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Default service environment file secrets path";
      };

      fingerprint = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Default PBS_FINGERPRINT environment variable value";
      };

      namespace = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Default namespace";
      };

      keyFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Default key file path";
      };

      additionalFlags = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description =
          "Additional flags passed to proxmox-backup-client backup command";
      };

      jobs = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            paths = mkOption {
              type = types.listOf (types.submodule {
                options = {
                  type = mkOption {
                    type = types.enum [ "pxar" "img" ];
                    default = "pxar";
                    description = "Archive type";
                  };

                  name = mkOption {
                    type = types.strMatching "^[a-zA-Z_-]+$";
                    description = "Archive name";
                  };

                  path = mkOption {
                    type = types.path;
                    description = "Path of backup";
                  };
                };
              });
              description = "Paths to backup";
            };

            startAt = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Backup timer. Defaults to name of attr";
            };

            environment = mkOption {
              type = types.attrsOf types.str;
              default = cfg.environment;
              description = "Service environment variables";
            };

            envFile = mkOption {
              type = types.path;
              default = cfg.envFile;
              description = "Service environment file secrets path";
            };

            fingerprint = mkOption {
              type = types.nullOr types.str;
              default = cfg.fingerprint;
              description = "PBS_FINGERPRINT environment variable value";
            };

            namespace = mkOption {
              type = types.nullOr types.str;
              default = cfg.namespace;
              description = "Namespace";
            };

            keyFile = mkOption {
              type = types.nullOr types.path;
              default = cfg.keyFile;
              description = "Key file path";
            };

            additionalFlags = mkOption {
              type = types.listOf types.str;
              default = cfg.additionalFlags;
              description =
                "Additional flags passed to proxmox-backup-client backup command";
            };
          };
        });
        default = { };
      };
    };
  };

  config = let
    obj = mapAttrs (name: conf: {
      name = "proxmox-backup-${name}";
      value = {
        path = with pkgs; [ proxmox-backup-client ];
        environment = conf.environment
          // (lib.optionalAttrs (conf.fingerprint != null) {
            PBS_FINGERPRINT = conf.fingerprint;
          });
        serviceConfig = {
          User = "root";
          Group = "root";
          EnvironmentFile = conf.envFile;
        };
        script = ''
          proxmox-backup-client backup \
            ${
              lib.optionalString (conf.keyFile != null)
              "--keyfile ${conf.keyFile}"
            } \
            ${
              lib.optionalString (conf.namespace != null)
              "--ns ${conf.namespace}"
            } \
            ${builtins.toString conf.additionalFlags} \
            ${
              builtins.toString
              (map (p: "${p.name}.${p.type}:${p.path}") conf.paths)
            }
        '';
        startAt = if conf.startAt != null then conf.startAt else name;
      };
    }) cfg.jobs;
  in mkIf cfg.enable ({
    systemd.services =
      (builtins.listToAttrs (map (key: getAttr key obj) (attrNames obj)));
  });
}
