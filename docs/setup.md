# Setup

Setup is simply a shell script to perform a configuration of various kinds.

Setup will perform after all package installation has successfully installed.

Common use cases for setup could be...

- Symlink a directory or file, such as software configurations
- Generate SSH keypairs
- Update default shell
- Installing fonts

Under the hood, both package and setup is basically the same. The only different
is how it get used and when do each get run.

You can setup the system using a package but it might not be the best place to
do since the package collection process is not yet finish and could end up in
an undesired outcome.

## Create a new setup

To create a setup, which is exactly the same as package but with different
directory, create a new shell file with `.sh` extension under
`setup` directory. The file name will be the setup name and should be
named in a kebab-case with no spacing and special characters (to prevent a
conflict with shell escaping).

An example setup to generate SSH keypairs would look something like this.

```sh
#!/bin/sh

set -e

if
  ! (command -v force_print >/dev/null 2>&1) ||
  ! (force_print 3 a b >/dev/null 2>&1) ||
  test "$(force_print 3 a b)" != "a  b";
then
  printf "Please run this script through \"install.sh\" instead"
  exit 1
fi

add_setup 'setup_ssh'

try_generate_keypair__has_generate=0
try_generate_keypair() {
  try_generate_keypair__path="$HOME/$DOTFILES/configs/ssh/$1.id_rsa"
  if test -f "$try_generate_keypair__path"; then
    info "SSH keypair for $1 is already exists"
  else
    step "Generating SSH keypair for $1..."
    ssh-keygen -b 2048 -t rsa -f "$try_generate_keypair__path" -q -N ""

    if test "$try_generate_keypair__has_generate" -eq 0; then
        add_post_install_message "Revoke and reassign a new SSH keypair"
        try_generate_keypair__has_generate=1
    fi
  fi
}

setup_ssh() {
  # generate SourceHut key pair
  try_generate_keypair srht

  # generate GitHub key pair
  try_generate_keypair github

  # generate GitLab key pair
  try_generate_keypair gitlab

  # generate Digital Ocean key pair
  try_generate_keypair digitalocean
}
```

For more detail breakdown, check out [package](/docs/package.md) documentation.

The main different apart from a package is on the `add_setup` line.

```sh
add_setup 'setup_ssh'
```

Similar to adding a custom installation (`use_custom`), `add_setup` is also
accept a function name that would get called during the setup process. Though
setup cannot be skipped (through the regular mean of APIs).

While the setup cannot be skipped, it can requested for a package to be
installed (`require`) or determine if it should get setup based on the package
collection (`depends`).

Check out available [built-in API](/lib) on how to call one.

For all available API to help with the setup, check out [systems API](/systems).

The rest of the file is simply defined a function `setup_ssh` that called
`try_generate_keypair` for each keypair type, by checking for the existing
keypair and only generate the one that is not exists.

```sh
# ...

try_generate_keypair__has_generate=0
try_generate_keypair() {
  try_generate_keypair__path="$HOME/$DOTFILES/configs/ssh/$1.id_rsa"
  if test -f "$try_generate_keypair__path"; then
    info "SSH keypair for $1 is already exists"
  else
    step "Generating SSH keypair for $1..."
    ssh-keygen -b 2048 -t rsa -f "$try_generate_keypair__path" -q -N ""

    if test "$try_generate_keypair__has_generate" -eq 0; then
        add_post_install_message "Revoke and reassign a new SSH keypair"
        try_generate_keypair__has_generate=1
    fi
  fi
}

setup_ssh() {
  # generate SourceHut key pair
  try_generate_keypair srht

  # generate GitHub key pair
  try_generate_keypair github

  # generate GitLab key pair
  try_generate_keypair gitlab

  # generate Digital Ocean key pair
  try_generate_keypair digitalocean
}
```
