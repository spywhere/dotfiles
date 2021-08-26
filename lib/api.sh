#!/bin/sh

_has_skip() {
  has_skip__component="$1"
  _has_item "$_SKIPPED" "$has_skip__component"
}

_has_indicate() {
  has_indicate__component="$1"
  _has_item "$_INDICATED" "$has_indicate__component"
}

has_flag() {
  has_flag__flag="$1"
  _has_item "$_INTERNAL_STATE" "$has_flag__flag"
}

# has_cmd <command>
has_cmd() {
  has_cmd__cmd="$1"
  test -n "$(command -v "$has_cmd__cmd")"
}

# has_package <package>
has_package() {
  has_package__package="$1"
  _has_item_in_list "$_LOADED" "$has_package__package"
}

add_post_install_message() {
  _POST_INSTALL_MSGS="$(_add_to_list "$_POST_INSTALL_MSGS" "$1")"
}

full_clone() {
  full_clone__repo="$1"
  full_clone__dir_name="$2"
  full_clone__name="$3"
  shift
  if test -n "$full_clone__dir_name"; then
    shift
  fi
  _try_git
  if test -n "$full_clone__name"; then
    shift
    step "Cloning $full_clone__name..."
  fi

  # shellcheck disable=SC2068
  cmd git clone $@ "$full_clone__repo" "$full_clone__dir_name"
}

# shellcheck disable=SC2120
deps() {
  if test -n "$1"; then
    if ! test -d "$HOME/$DOTFILES/.deps"; then
      mkdir -p "$HOME/$DOTFILES/.deps"
    fi

    printf "%s/%s/.deps/%s" "$HOME" "$DOTFILES" "$1"
  else
    printf "%s/%s/.deps" "$HOME" "$DOTFILES"
  fi
}

# Skip installation as fulfilled if specific file is exist
# has_directory <directory>
has_file() {
  if test -n "$_FULFILLED"; then
    return
  fi
  if test -f "$1"; then
    _FULFILLED="fulfilled"
  fi
}

# Skip installation as fulfilled if specific directory is exist
# has_directory <directory>
has_directory() {
  if test -n "$_FULFILLED"; then
    return
  fi
  if test -d "$1"; then
    _FULFILLED="fulfilled"
  fi
}

# Skip installation as fulfilled if specific command is exist
# has_executable <executable>
has_executable() {
  if test -n "$_FULFILLED"; then
    return
  fi
  if has_cmd "$1"; then
    _FULFILLED="fulfilled"
  fi
}

# Mark current script as optional
optional() {
  if test -n "$_SKIP_OPTIONAL"; then
    return
  fi
  _FULFILLED="optional"
}

# Skip installation if the package is not being installed
# depends <package>
depends() {
  if test -n "$_FULFILLED"; then
    return
  fi

  depends__package="$1"
  if has_package "$depends__package"; then
    return
  fi

  _FULFILLED="fulfilled"
}

# Install package regardless of skipped components
# require <package>
require() {
  if test -n "$_FULFILLED"; then
    return
  fi

  require__package="$1"

  # Depends on itself
  if test "$_RUNNING" = "$require__package"; then
    return
  fi

  if has_package "$require__package"; then
    return
  fi

  # Dependency not found
  if ! test -f "$HOME/$DOTFILES/packages/$require__package.sh"; then
    error "$_RUNNING_TYPE \"$_RUNNING\" is depends on \"$require__package\""
    _HALT=1
    return
  fi

  require__old_running_type="$_RUNNING_TYPE"
  require__old_running="$_RUNNING"
  require__old_fulfilled="$_FULFILLED"
  _RUNNING_TYPE="package"
  _RUNNING="$require__package"
  _SKIP_OPTIONAL="1"
  _FULFILLED=""
  # Add package to the loaded list (prevent dependency cycle)
  _LOADED=$(_add_to_list "$_LOADED" "$_RUNNING")

  . "$HOME/$DOTFILES/packages/$require__package.sh"

  _RUNNING_TYPE="$require__old_running_type"
  _RUNNING="$require__old_running"
  _SKIP_OPTIONAL=""
  _FULFILLED="$require__old_fulfilled"
}

# Add package into installation list
# add_package [display name]
# Fields:
#   + manager      : string
#   - manager_name : string
#   + package      : string
#   - package_name : string
add_package() {
  if test -n "$_FULFILLED"; then
    reset_object
    return
  fi

  field package_name "$1"
  _PACKAGES="$(_add_to_list "$_PACKAGES" "$(make_object)")"
  reset_object

  _FULFILLED="fulfilled"
}

# Add custom function into installation list if no valid setup available
# use_custom <function> [display name]
# Fields:
#   + fn           : function
#   - package_name : string
use_custom() {
  if _has_skip custom; then
    return
  fi

  if test -n "$_FULFILLED"; then
    reset_object
    return
  fi

  field fn "$1"
  if test -n "$2"; then
    field package_name "$2"
  else
    field package_name "$_RUNNING"
  fi
  _CUSTOM="$(_add_to_list "$_CUSTOM" "$(make_object)")"
  reset_object
  _FULFILLED="fulfilled"
}

# Add docker build into installation list if no valid setup available
# use_docker_build [display name]
# Fields:
#   - package_name : string
use_docker_build() {
  if _has_skip docker; then
    return
  fi
  use_docker_build__package="$_RUNNING"
  if test -n "$_FULFILLED"; then
    reset_object
    return
  fi

  use_docker_build__dockerfile="$HOME/$DOTFILES/docker/$use_docker_build__package/Dockerfile.$OS"
  if ! test -f "$use_docker_build__dockerfile"; then
    use_docker_build__dockerfile="$HOME/$DOTFILES/docker/$use_docker_build__package/Dockerfile.$OSKIND"
  fi
  if ! test -f "$use_docker_build__dockerfile"; then
    if test "$OS" = "$OSKIND"; then
      warn "Docker build for package \"$use_docker_build__package\" is not available on $OS"
    else
      warn "Docker build for package \"$use_docker_build__package\" is not available on $OS/$OSKIND"
    fi
    reset_object
    return
  fi

  if test -z "$_DOCKER"; then
    require 'docker'
  fi

  field package "$use_docker_build__package"
  field package_name "$1"
  _DOCKER="$(_add_to_list "$_DOCKER" "$(make_object)")"
  reset_object

  _FULFILLED="fulfilled"
}

# Add custom function into setup list if no valid setup available
# add_setup <function> [display name]
# Fields:
#   + fn           : function
#   - display_name : string
add_setup() {
  if test -n "$_FULFILLED"; then
    reset_object
    return
  fi

  field fn "$1"
  if test -n "$2"; then
    field display_name "$2"
  else
    field display_name "$_RUNNING"
  fi
  _SETUP="$(_add_to_list "$_SETUP" "$(make_object)")"
  reset_object
}
