#!/usr/bin/env python3

import os
import shlex
import shutil
import subprocess
import sys


def sketchybar_path():
    path = shutil.which("sketchybar")
    if path is None:
        raise RuntimeError("sketchybar was not found in PATH")
    return path


def main():
    config_dir = os.environ.get("CONFIG_DIR")
    if not config_dir:
        raise RuntimeError("CONFIG_DIR is not set")

    sketchybar = sketchybar_path()
    plugin = os.path.join(config_dir, "plugins", "battery.py")
    plugin_command = "{} {}".format(
        shlex.quote(sys.executable),
        shlex.quote(plugin),
    )

    subprocess.run(
        [
            sketchybar,
            "--add",
            "item",
            "battery.status",
            "right",
            "--set",
            "battery.status",
            "label.font.size=8",
            "label.y_offset=5",
            "label.width=30",
            "width=0",
        ],
        check=True,
    )

    subprocess.run(
        [
            sketchybar,
            "--add",
            "item",
            "battery",
            "right",
            "--set",
            "battery",
            "update_freq=30",
            "script={}".format(plugin_command),
            "icon.font=SF Pro:Regular:18",
            "label.font.size=8",
            "label.y_offset=-5",
            "label.width=30",
            "--subscribe",
            "battery",
            "system_woke",
            "power_source_change",
        ],
        check=True,
    )


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        print("battery item: {}".format(error), file=sys.stderr)
        sys.exit(1)
