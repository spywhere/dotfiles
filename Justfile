set quiet

nix := "nix --extra-experimental-features \"nix-command flakes\""

_default:
  just --list

repl:
  {{ nix }} repl

flake-check:
  {{ nix }} flake check ~/.dots-nix?shallow=1

darwin-check PROFILE:
  sudo {{ nix }} run nix-darwin/master#darwin-rebuild -- check --flake .#{{ PROFILE }}
