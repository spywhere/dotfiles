# Dotfiles

## Required Commands

- coreutils
  - `uname`

## Supported Platform

- macOS
- Linux
  - Debian (Raspberry OS)
  - Alpine

## Just run

```sh
sh -c "$(curl -sSL bit.do/spywhere-dotfiles)"
```

or

```sh
sh -c "$(curl -sSL git.io/JvZB8)"
```

## Development

To run the setup without auto updating use

```sh
sh install.sh -l
```

To simulate a remote setup use one of these commands

```sh
sh -c "$(cat install.sh)" - [args...]
```

```sh
cat install.sh | sh -s -- [args...]
```
