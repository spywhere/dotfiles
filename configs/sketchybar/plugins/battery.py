#!/usr/bin/env python3

"""SketchyBar battery plugin — reads pmset and updates battery items."""

import os
import re
import subprocess
import sys

PMSET = "/usr/bin/pmset"

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
LIB_DIR = os.path.join(os.path.dirname(SCRIPT_DIR), "lib")
if LIB_DIR not in sys.path:
    sys.path.insert(0, LIB_DIR)

from sketchybar_api import SketchyBar


def battery_state():
    """Parse pmset output and return battery state dict or None."""
    result = subprocess.run(
        [PMSET, "-g", "batt"],
        check=False,
        stdout=subprocess.PIPE,
        text=True,
    )
    if result.returncode != 0:
        return None

    stdout = result.stdout
    percentage_match = re.search(r"(\d+)%", stdout)
    if percentage_match is None:
        return None

    remaining_match = re.search(r"(\d+:\d+) remaining", stdout)
    return {
        "percentage": percentage_match.group(1),
        "use_ac": "AC Power" in stdout,
        "not_charging": "not charging" in stdout,
        "remaining": remaining_match.group(1) if remaining_match else "",
    }


def icon_and_color(percentage):
    """Return (icon, color) for a discharging battery."""
    pct = int(percentage)
    if 90 <= pct <= 100:
        return "\U001006e8", "0xffffffff"
    if 60 <= pct <= 89:
        return "\U00100eb8", "0xffffffff"
    if 30 <= pct <= 59:
        return "\U00100eb6", "0xffffcc66"
    if 10 <= pct <= 29:
        return "\U001006e9", "0xffff9933"
    return "\U001006ea", "0xffff6666"


def main():
    state = battery_state()
    if state is None:
        return

    percentage = state["percentage"]
    use_ac = state["use_ac"]
    not_charging = state["not_charging"]
    remaining = state["remaining"]

    name = os.environ.get("NAME")
    if not name:
        return

    bar = SketchyBar()
    battery = bar.item(name)
    status = bar.item("{}.status".format(name))

    # Determine icon, color, and alignment
    align = "left"
    if use_ac:
        icon = "\U0010088b"
        color = "0xff00aaff"
        if not_charging:
            remaining = "\U00100285"
            align = "center"
        elif remaining == "0:00":
            remaining = ""
    else:
        icon, color = icon_and_color(percentage)

    # Layout and animation
    if not remaining:
        # One-line layout: fade out status, enlarge main label
        width = 45 if percentage == "100" else 40
        with bar.animate("sin", 10) as anim:
            anim.set(
                status,
                {"label.color.alpha": 0, "label.align": align},
            )
            anim.set(
                battery,
                {
                    "label.y_offset": 0,
                    "label.font.size": 13,
                    "label.width": width,
                    "label.color": color,
                },
            )
    else:
        # Two-line layout: show remaining in status, compact main label
        battery_props = {
            "label.font.size": 8,
            "label.width": 30,
            "label.color": color,
        }
        if str(battery.get("label.y_offset")) != "-5":
            battery_props["label.y_offset"] = -5

        with bar.animate("sin", 10) as anim:
            anim.set(
                status,
                {"label.color": color, "label.align": align},
            )
            anim.set(battery, battery_props)
        status.set(label=remaining)

    # Final icon and percentage
    battery.set(icon=icon, label="{}%".format(percentage))


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError) as error:
        print("battery plugin: {}".format(error), file=sys.stderr)
        sys.exit(1)
