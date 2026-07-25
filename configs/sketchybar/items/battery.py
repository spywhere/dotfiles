#!/usr/bin/env python3

"""SketchyBar battery item setup."""

import os
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
LIB_DIR = os.path.join(os.path.dirname(SCRIPT_DIR), "lib")
if LIB_DIR not in sys.path:
    sys.path.insert(0, LIB_DIR)

from sketchybar_api import SketchyBar


def main():
    config_dir = os.environ.get("CONFIG_DIR")
    if not config_dir:
        raise RuntimeError("CONFIG_DIR is not set")

    bar = SketchyBar(config_dir=config_dir)

    # battery.status (secondary label for remaining time)
    status = bar.add(SketchyBar.Item("battery.status"), position="right")
    status.set(
        {
            "label.font.size": 8,
            "label.y_offset": 5,
            "label.width": 30,
        },
        width=0,
    )

    # battery (primary item with icon and percentage)
    battery = bar.add(SketchyBar.Item("battery"), position="right")
    plugin = bar.python_plugin(
        os.path.join(config_dir, "plugins", "battery.py")
    )
    battery.set(
        {
            "icon.font": "SF Pro:Regular:18",
            "label.font.size": 8,
            "label.y_offset": -5,
            "label.width": 30,
            "script": plugin,
        },
        update_freq=30,
    )
    battery.subscribe("system_woke", "power_source_change")


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        print("battery item: {}".format(error), file=sys.stderr)
        sys.exit(1)
