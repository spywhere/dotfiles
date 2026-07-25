#!/usr/bin/env python3

"""SketchyBar aerospace item setup."""

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
    plugin = bar.python_plugin(os.path.join("plugins", "aerospace.py"))

    bar.add_event("aerospace_workspace_change")
    bar.add_event("aerospace_mode_change")

    # service mode icon
    mode = bar.add(SketchyBar.Item("aerospace.mode"), position="left")
    mode.set(
        {
            "icon": "\U0010090a",
            "drawing": "off",
            "script": plugin,
        }
    )
    mode.subscribe("aerospace_mode_change")

    # controller item — drives workspace reconciliation
    controller = bar.add(SketchyBar.Item("aerospace"), position="left")
    controller.set(
        {
            "drawing": "off",
            "script": plugin,
        }
    )
    controller.subscribe(
        "aerospace_workspace_change",
        "display_change",
        "system_woke",
        "front_app_switched",
    )

    # Initial sync: invoke the plugin with argv fallback
    # (matches shell's "$CONFIG_DIR/plugins/aerospace.sh aerospace")
    subprocess.run(
        [sys.executable, os.path.join(config_dir, "plugins", "aerospace.py"), "aerospace"],
        check=False,
        env=os.environ.copy(),
    )


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        print("aerospace item: {}".format(error), file=sys.stderr)
        sys.exit(1)
