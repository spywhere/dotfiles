# Main

1. Detect OS and Architecture
2. Flags processing
3. Package specifications processing
4. Clone repo if no local copy found (See git Detection)
5. Change working directory to local copy
6. Try updating local copy to the latest version
    - Unless specified or just did 4.
7. Execute local copy installation script if running remotely
8. This should be safe to include core libs here
9. Print available packages / setup and quit according to the flags in 2.
10. Testing basic commands
11. Ready!

## Required Commands

- `uname`
- `git` or `curl`

## Required Functionalities

- quit
- _usage
  - print
- _info
- error
- add_flag
  - add_item
- clone
- _try_git
- step
- cmd

# git Detection

1. Test if command `git` is available
2. Test if running remotely, if so
    1. Test if command `curl` is available
    2. Download and source base system files
    3. Download and source target system files
3. Run base system files
4. Run target system files
5. Install git otherwise error with git required

# Download system files

```
_download_system_file() {
  if test "$(curl --create-dirs -fsL "$1" -o "$2" -w "%{http_code}")" -eq 200; then
    return 0
  fi
  return 1
}
```

```
main__system_deps="$(deps systems)"

system_url="$(printf "$SYSTEM_FILES" "base")"
print "Downloading system files ($system_url)..."
if ! _download_system_file "$system_url" "$main__system_deps/base"; then
  quit 1
fi
. "$main__system_deps/base"

system_url="$(printf "$SYSTEM_FILES" "$OS")"
print "Downloading system files ($system_url)..."
if _download_system_file "$system_url" "$main__system_deps/$OS"; then
  . "$main__system_deps/$OS"
else
  print "$OS is not natively supported, trying $OSKIND..."
  system_url="$(printf "$SYSTEM_FILES" "$OSKIND")"
  print "Downloading system files ($system_url)..."
  if _download_system_file "$system_url" "$main__system_deps/$OSKIND"; then
    . "$main__system_deps/$OSKIND"
  else
    print "System $OS is not supported"
    quit 1
  fi
fi
```
