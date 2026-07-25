#!/usr/bin/env python3

import json
import os
import re
import shutil
import subprocess
import sys

PMSET = "/usr/bin/pmset"


def sketchybar_path():
    path = shutil.which("sketchybar")
    if path is None:
        raise RuntimeError("sketchybar was not found in PATH")
    return path


def run_sketchybar(sketchybar, arguments):
    subprocess.run([sketchybar] + arguments, check=True)


def current_y_offset(sketchybar, name):
    result = subprocess.run(
        [sketchybar, "--query", name],
        check=False,
        stdout=subprocess.PIPE,
        text=True,
    )
    if result.returncode != 0:
        return None

    try:
        return str(json.loads(result.stdout)["label"]["y_offset"])
    except (KeyError, TypeError, ValueError):
        return None


def battery_state():
    result = subprocess.run(
        [PMSET, "-g", "batt"],
        check=False,
        stdout=subprocess.PIPE,
        text=True,
    )
    if result.returncode != 0:
        return None

    percentage_match = re.search(r"(\d+)%", result.stdout)
    if percentage_match is None:
        return None

    remaining_match = re.search(r"(\d+:\d+) remaining", result.stdout)
    return {
        "percentage": percentage_match.group(1),
        "use_ac": "AC Power" in result.stdout,
        "not_charging": "not charging" in result.stdout,
        "remaining": remaining_match.group(1) if remaining_match else "",
    }


def icon_and_color(percentage):
    value = int(percentage)
    if 90 <= value <= 99 or value == 100:
        return "􀛨", "0xffffffff"
    if 60 <= value <= 89:
        return "􀺸", "0xffffffff"
    if 30 <= value <= 59:
        return "􀺶", "0xffffcc66"
    if 10 <= value <= 29:
        return "􀛩", "0xffff9933"
    return "􀛪", "0xffff6666"


def main():
    state = battery_state()
    if state is None:
        return

    sketchybar = sketchybar_path()
    name = os.environ.get("NAME", "")
    percentage = state["percentage"]
    remaining = state["remaining"]
    icon, label_color = icon_and_color(percentage)
    align = "left"

    if state["use_ac"]:
        icon = "􀢋"
        label_color = "0xff00aaff"
        if state["not_charging"]:
            remaining = "􀊅"
            align = "center"
        elif remaining == "0:00":
            remaining = ""

    if not remaining:
        width = "45" if percentage == "100" else "40"
        run_sketchybar(
            sketchybar,
            [
                "--animate",
                "sin",
                "10",
                "--set",
                "{}.status".format(name),
                "label.color.alpha=0",
                "label.align={}".format(align),
                "--set",
                name,
                "label.y_offset=0",
                "label.font.size=13",
                "label.width={}".format(width),
                "label.color={}".format(label_color),
            ],
        )
    else:
        arguments = [
            "--animate",
            "sin",
            "10",
            "--set",
            "{}.status".format(name),
            "label.color={}".format(label_color),
            "label.align={}".format(align),
            "--set",
            name,
            "label.font.size=8",
            "label.width=30",
            "label.color={}".format(label_color),
        ]
        if current_y_offset(sketchybar, name) != "-5":
            arguments.append("label.y_offset=-5")
        run_sketchybar(sketchybar, arguments)
        run_sketchybar(
            sketchybar,
            ["--set", "{}.status".format(name), "label={}".format(remaining)],
        )

    run_sketchybar(
        sketchybar,
        [
            "--set",
            name,
            "icon={}".format(icon),
            "label={}%".format(percentage),
        ],
    )


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        print("battery plugin: {}".format(error), file=sys.stderr)
        sys.exit(1)
