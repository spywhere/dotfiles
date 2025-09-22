#!/bin/sh

write_nix() {
  cat <<'EOF'
{ config, lib, pkgs, profile, ...}:
let
  package = import ../core/package.nix {
    inherit lib;
    inherit profile;
    inherit config;
  };
  inherit (package) mkPackage;
EOF
  printf 'in mkPackage %s {\n' "$1"
  if test -n "$2"; then
    printf '  optional = true;\n'
  fi
  if test -n "$3"; then
    printf '  only = [ %s ];\n' "$3"
  fi
  if test -n "$4"; then
    printf '  except = [ %s ];\n' "$4"
  fi
  printf '  config = {\n'
  printf '    %s = [ %s ];\n' "$5" "$6"
  printf '  };\n}\n'
}

contains() {
  printf '%s' "$1" | grep -q "$2"
}

read_match() {
  printf '%s' "$1" | awk "/$2/{print}"
}

normalize() {
  sed "s/^'*/\"/" | sed "s/'*$/\"/" | sed "s/' '/ /g"
}

strip() {
  sed "s/^'*//" | sed "s/'*$//" | sed "s/' '/ /g"
}

item_at() {
  cut -d' ' -f"$1"-
}

parse_profiles() {
  kind="$1"
  shift
  if test "$1" = "profile"; then
    shift
  else
    return
  fi
  output=""
  while test -n "$1"; do
    case "$1" in
      -*)
        if test "$kind" != "except"; then
          shift
          continue
        fi
        ;;
      *)
        if test "$kind" != "only"; then
          shift
          continue
        fi
        ;;
    esac
    if test -n "$output"; then
      output="$output "
    fi
    output="\"$(printf '%s' "$1" | sed 's/^-//')\""
    shift
  done
  printf '%s' "$output"
}

migrate_to_nix() {
  source="$1"
  destination="$(printf '%s' "$source" | sed 's/\.sh/.nix/')"
  package="$2"
  manager="$3"
  write_nix "$(basename "$1" | sed 's/\.sh$//' | normalize)" "$4" "$5" "$6" "$manager" "$package" >"$destination"
}

validate_package() {
  content="$(cat "$1")"
  optional=""
  only=""
  except=""
  if contains "$content" optional; then
    optional="1"
  fi
  if contains "$content" profile; then
    profiles="$(read_match "$content" profile)"
    only="$(parse_profiles only $profiles)"
    except="$(parse_profiles except $profiles)"
  fi

  if contains "$content" "use_nix"; then
    migrate_to_nix "$1" "pkgs.$(read_match "$content" "use_nix" | item_at 3 | strip)" nixpkgs.add "$optional" "$only" "$except"
  elif contains "$content" "use_brew formula"; then
    migrate_to_nix "$1" "$(read_match "$content" "use_brew formula" | item_at 3 | normalize)" brew.add.formula "$optional" "$only" "$except"
  elif contains "$content" "use_brew cask"; then
    migrate_to_nix "$1" "$(read_match "$content" "use_brew cask" | item_at 3 | normalize | xargs sh -c 'out="";for i in $*; do case "$1" in -*) continue;; *);; esac;if test -n "$out"; then out="$out ";fi;out="$out\"$i\""; done; printf "%s" "$out"' sh)" brew.add.cask "$optional" "$only" "$except"
  elif contains "$content" "use_brew_tap"; then
    migrate_to_nix "$1" "$(read_match "$content" "use_brew_tap" | item_at 2 | normalize | xargs sh -c 'out="";for i in $*; do case "$1" in -*) continue;; *);; esac;if test -n "$out"; then out="$out ";fi;out="$out\"$i\""; done; printf "%s" "$out"' sh)" brew.add.tap "$optional" "$only" "$except"
  # elif contains "$content" "has_executable"; then
  #   migrate_to_nix "$1" "pkgs.$(read_match "$content" "has_executable" | item_at 2 | strip)" nixpkgs.add "$optional" "$only" "$except"
  else
    printf ' skipped\n'
    return 1
  fi
  printf '\r                                         \r'
}

for package in ./packages/*.sh; do
  printf 'Migrating %s...' "$(basename "$package")"
  validate_package "$package"
done
