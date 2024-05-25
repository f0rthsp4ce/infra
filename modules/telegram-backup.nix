{ lib, config, pkgs, ... }:

with lib;

let cfg = config.services.telegram-backup;
in {
  options = {
    services.telegram-backup = {
      enable = mkEnableOption "Whether to enable telegram backups";

      enable-defaults = mkEnableOption "Whether to add default secret config";

      gpgKeys = mkOption {
        type = types.listOf types.str;
        default = [ "5F3D9D3DECE08651DE14D29FACAD4265E193794D" ];
        description = "Encryption key";
      };

      envFile = mkOption {
        type = types.path;
        default = config.age.secrets.credentials-telegram-backup.path;
        description = "Service environment file secrets path";
      };

      timers = mkOption {
        type = types.attrsOf (types.listOf types.str);
        default = { };
      };
    };
  };

  config = let
    obj = mapAttrs (timer: paths: {
      name = "telegram-backup-${timer}";
      value = {
        path = with pkgs; [ gnupg curl zip ];
        serviceConfig = {
          User = "root";
          Group = "root";
          EnvironmentFile = cfg.envFile;
        };
        script = ''
          set -e
          set -x

          name='/tmp/${networking.hostName}-${timer}-telegram-backup.zip'

          rm $name || true
          zip -9r "$name" ${toString paths}
          gpg --no-tty --keyserver keys.openpgp.org --recv-keys "${
            toString cfg.gpgKeys
          }"
          gpg --batch --trust-model always -o "$name.gpg" --encrypt "${
            map (key: "-r ${key}") cfg.gpgKeys
          }" "$name"

          file_size=$(stat --printf="%s" "$name.gpg")
          chunk_size=$((49*1024*1024))  # 49 megabytes

          if (( file_size > chunk_size )); then
              split -b "$chunk_size" "$name.gpg" "$name.gpg.part"

              for part_file in $name.gpg.part*; do
                  curl -F document=@"$part_file" "https://api.telegram.org/bot$TOKEN/sendDocument?chat_id=$CHAT_ID&caption=${networking.hostName}"
              done

              rm "$name.gpg.part"*
          else
              curl -F document=@"$name.gpg" "https://api.telegram.org/bot$TOKEN/sendDocument?chat_id=$CHAT_ID&caption=${networking.hostName}"
          fi

          rm "$name" "$name.gpg" || true
        '';
        startAt = timer;
      };
    }) cfg.timers;
  in mkIf cfg.enable ((mkIf cfg.enable-defaults {
    age.secrets.credentials-telegram-backup.file =
      ../secrets/credentials/telegram-backup.age;
  }) // {
    systemd.services =
      (builtins.listToAttrs (map (key: getAttr key obj) (attrNames obj)));
  });
}
