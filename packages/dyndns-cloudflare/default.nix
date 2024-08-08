{ writers, python3Packages, ... }:

writers.writePython3Bin "dyndns-cloudflare" {
  libraries = with python3Packages; [ requests cloudflare ];
  flakeIgnore = [ "E302" "E501" "E305" ];
} (builtins.readFile ./main.py)
