# Dotfiles

## Required Built-in Commands
- `cd`
- `rm`
- `set`
- `shift`
- `printf`
- `test`
- `command`
- `expr`
- `exit`
- `if`
- `while`
- `case`
- `return`

## Required Commands
- coreutils
  - `uname`
  - `expr`

## Supported Platform
- macOS
- Linux
  - Raspberry OS
  - Alpine

## Just run
```
curl -sSL bit.do/spywhere-dotfiles | sh
```

or

```
curl -sSL git.io/JvZB8 | sh
```

## Development

To run the setup without updating use

```
sh install.sh -l
```

To simulate a remote setup use

```
cat install.sh | sh -s -- [args...]
```
