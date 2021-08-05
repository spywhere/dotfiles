#!/bin/sh

_prepare_packages() {
  if ! _has_skip package || test -n "$_INDICATED"; then
    for try_run_install__package_path in "$HOME/$DOTFILES/packages"/*.sh; do
      try_run_install__package=$(basename "$try_run_install__package_path")
      try_run_install__package=${try_run_install__package%.sh}

      print_inline "$esc_yellow==>$esc_reset Checking package $try_run_install__package..."

      # Skip requested packages
      if (_has_skip package || _has_skip "$try_run_install__package") && ! _has_indicate "$try_run_install__package"; then
        continue
      fi

      # Package could be loaded from the dependency list
      if has_package "$try_run_install__package"; then
        continue
      fi

      _RUNNING="$try_run_install__package"
      _FULFILLED=""
      # Add package to the loaded list (prevent dependency cycle)
      _LOADED=$(_add_to_list "$_LOADED" "$_RUNNING")
      . "$try_run_install__package_path"

      # Remove optional packages from the loaded list
      if test "$_FULFILLED" = "optional"; then
        try_run_install__new_loaded=""
        eval "set -- $_LOADED"
        for try_run_install__loaded_package in "$@"; do
          if test "$try_run_install__loaded_package" = "$_RUNNING"; then
            continue
          fi
          try_run_install__new_loaded=$(_add_to_list "$try_run_install__new_loaded" "$try_run_install__loaded_package")
        done
        _LOADED="$try_run_install__new_loaded"
      fi
    done
  fi
}

_summarize_packages() {
  if test -n "$_PACKAGES"; then
    print "$esc_green==>$esc_reset The following packages will be installed:"
    eval "set -- $_PACKAGES"
    for try_run_install__package in "$@"; do
      try_run_install__manager_name="$(parse_field "$try_run_install__package" manager_name)"
      try_run_install__package_name="$(parse_field "$try_run_install__package" package_name)"
      if test -z "$try_run_install__manager_name"; then
        try_run_install__manager_name="$(parse_field "$try_run_install__package" manager)"
      fi

      if test -z "$try_run_install__package_name"; then
        try_run_install__package_name="$(parse_field "$try_run_install__package" package)"
      fi

      if test -n "$try_run_install__manager_name"; then
        try_run_install__manager_name=" ${esc_blue}via$esc_reset $try_run_install__manager_name"
      fi

      print "  $esc_blue-$esc_reset $try_run_install__package_name$try_run_install__manager_name"
    done
  fi
}

_run_packages() {
  if test -n "$_PACKAGES"; then
    eval "set -- $_PACKAGES"
    install_packages "$@"
  fi
}
