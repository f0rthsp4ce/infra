{ writeScriptBin }:

writeScriptBin "upgrade-system" ''
  sudo rm -rf /root/.cache

  branch="$1"
  if [ -z "$branch" ]; then
    branch="main"
  fi

  sudo nixos-rebuild switch --flake "github:f0rthsp4ce/infra/$branch"
''
