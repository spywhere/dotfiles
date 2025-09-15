set quiet

nix := "nix --extra-experimental-features \"nix-command flakes\""
darwin-rebuild := "run nix-darwin/master#darwin-rebuild --"

_default:
  just --list

nix *REST:
  {{ nix }} {{ REST }}

flake *REST: (nix "flake" REST)

darwin-rebuild *REST:
  sudo {{ nix }} run nix-darwin/master#darwin-rebuild -- {{ REST }}

repl: (nix "repl")

eval TYPE PROFILE CONFIG:
  {{ nix }} eval --json '.#{{ TYPE }}Configurations.{{ PROFILE }}.config{{ CONFIG }}'

darwin-check PROFILE:
  sudo {{ nix }} {{ darwin-rebuild }} check --flake '.#{{ PROFILE }}'
