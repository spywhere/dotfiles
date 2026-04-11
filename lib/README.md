# Built-in APIs

Built-in APIs are functions that allow you to determine the installation state,
perform system changes and more.

## Package State

- `has_file <path>`: Skip if a file exists
  - `path`: File path
- `has_directory <path>`: Skip if a directory exists
  - `path`: Directory path
- `has_executable <executable>`: Skip if an executable exists
  - `executable`: Executable name
- `has_string <pattern> <executable> [args]...`: Skip if a string is matched
from the given command output
  - `pattern`: Grep pattern to match string
  - `executable`: Executable name
  - `args`: Arguments to passed to the executable
- `optional`: Skip unless required or depended by other packages
- `profile <profile>`: Mark as optional if current running profile is matched
  - `profile`: Profile name (prefixed with `-` to match the inversion, e.g.
`-ci` to match anything but `ci`)
- `depends <package>`: Skip if a package is not being installed
  - `package`: Package name
- `require <package>`: Force a package to be installed
  - `package`: Package name
- `has_profile <profile>`: Check if current running profile is matched
  - `profile`: Profile name (prefixed with `-` to match the inversion, e.g.
`-ci` to match anything but `ci`)
- `has_package <package>`: Check if a package is to be installed
  - `package`: Package name
- `mark_installed`: Mark a package as to be installed
- `add_package <name>`: Add a package to the package list unless marked as
installed
  - `name`: Package display name
  - Fields
    - `manager`: Package manager name
    - (Optional) `manager_name`: Package manager display name
    - `package`: Package name
    - (Optional) `package_name`: Package display name
- `add_post_install_message <message>`: Add post-installation messages
  - `message`: Message to be displayed
- `use_custom <function> [display name]`: Add a package to the custom
installation list
  - `function`: Function name to be called
  - `display name`: Name to be displayed on summary
- `add_setup <function> [display name]`: Add a setup to the setup list
  - `function`: Function name to be called
  - `display name`: Name to be displayed on summary

## Internal State

- `has_flag <name>`: Check if the specified flag is set
  - `name`: Flag name
- `add_flag <name>`: Set a specified flag
  - `name`: Flag name
- `field <name> <value>`: Add a new field to the intermediate object
  - `name`: Field name
  - `value`: Value to added
- `make_object`: Returns an object from the intermediate object
- `reset_object`: Reset the intermediate object state
- `has_field <object> <field>`: Check if the given object has the specified field
  - `object`: Object from `make_object`
  - `field`: Field name
- `parse_field <object> <field>`: Get a value from the specified field in a given object
  - `object`: Object from `make_object`
  - `field`: Field name

## Acquire System Information

- `has_cmd <command>`: Check if a specified command is exists
  - `command`: Command name to check

## System Changes

- `clone <repo> [name] [display name] [flags]...`: Shallow (depth 1) clone a
repository
  - `repo`: Git repository URL
  - `name`: Directory name for the repository
  - `display name`: Repository name to be displayed
  - `flags`: Flags to passed to Git clone command
- `full_clone <repo> [name] [display name] [flags]...`: Full clone a repository
  - `repo`: Git repository URL
  - `name`: Directory name for the repository
  - `display name`: Repository name to be displayed
  - `flags`: Flags to passed to Git clone command
- `download_file <url> <file>`
  - `url`: File URL to download
  - `file`: File name for the downloaded file
- `quiet_cmd <command>...`: Specified an alternative command with less verbose
logs for the next command
  - `command`: Command and its arguments to run with less verbose logs
- `quiet_flags <flags>...`: Specified quiet flags for the next command
  - `flags`: Command flags for less verbose logs
- `verbose_cmd <command>...`: Specified an alternative command with more verbose
logs for the next command
  - `command`: Command and its arguments to run with more verbose logs
- `verbose_flags <flags>...`: Specified verbose flags for the next command
  - `flags`: Command flags for more verbose logs
- `sudo_cmd <command>...`: Perform a command, escalated as root as needed
  - `command`: Command and its arguments to run
- `cmd <command>...`: Perform a command, based on the verbosity
  - `command`: Command and its arguments to run

## Helpers

- `deps [name]`: Returns a directory to store dependency artifacts
  - `name`: Returns a directory to store this specific dependency artifacts
- `substring <string> [start] [length]`: Cut a string into smaller pieces
  - `string`: String to cut
  - `start`: 0-based index of the string to start the cut
  - `length`: Length of string to cut (negative length supported)
