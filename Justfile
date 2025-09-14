set quiet

nix := "nix --extra-experimental-features \"nix-command flakes\""

_default:
  just --list

repl:
  {{ nix }} repl

eval TYPE PROFILE CONFIG:
  {{ nix }} eval --json '.#{{ TYPE }}Configurations.{{ PROFILE }}.config{{ CONFIG }}'

flake-check:
  {{ nix }} flake check

darwin-check PROFILE:
  sudo {{ nix }} run nix-darwin/master#darwin-rebuild -- check --flake '.#{{ PROFILE }}'
