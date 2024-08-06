#!/usr/bin/env bash
# nixfmt doesnt work properly with direnv. This scripts formats only .nix files.
find -type f -name "*.nix" | xargs nixfmt
