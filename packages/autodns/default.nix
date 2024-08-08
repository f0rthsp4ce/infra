{ writers, python3Packages, ... }:

writers.writePython3Bin "autodns" {
  libraries = with python3Packages; [ librouteros cloudflare ];
  flakeIgnore = [ "E" ];
} (builtins.readFile ./main.py)
