#!/usr/bin/env python3

import subprocess
import os
import re
import sys
import shutil

PMSET = "/usr/bin/pmset"

def run_sketchybar_command(*args):
    """Executes a sketchybar command."""
    executable = shutil.which("sketchybar")
    if not executable:
        print("sketchybar executable not found.", file=sys.stderr)
        return

    command = [executable, *args]
    try:
        subprocess.run(command, check=True, capture_output=True, text=True)
    except subprocess.CalledProcessError as e:
        print(f"Error executing sketchybar command: {' '.join(command)}", file=sys.stderr)
        print(f"Stderr: {e.stderr}", file=sys.stderr)
        print(f"Stdout: {e.stdout}", file=sys.stderr)
    except FileNotFoundError:
        print(f"'{executable}' command not found. Is SketchyBar installed and in PATH?", file=sys.stderr)

def battery_state() -> dict | None:
    """Parses battery status using pmset."""
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

def get_battery_icon_and_color(state: dict) -> tuple[str, str, str, str]:
    """Determines icon, color, remaining indicator, and alignment."""
    percentage = int(state["percentage"])
    use_ac = state["use_ac"]
    not_charging = state["not_charging"]
    remaining = state["remaining"]

    icon = ""
    label_color = "0xffffffff"
    remaining_indicator = ""
    align = "left"

    if use_ac:
        icon = "􀢋"  # Plug icon
        label_color = "0xff00aaff" # Blue for AC power
        if not_charging:
            remaining_indicator = "􀊅" # Exclamation mark for not charging
            align = "center"
        elif percentage == 100: # Full charge, no time remaining
            remaining_indicator = ""
            align = "left"
        else:
            # If AC power and charging, we might not show remaining time,
            # or we could show "Charging..." if pmset provides that info.
            # For now, we'll keep it empty if not specifically "not charging".
            remaining_indicator = ""
            align = "left"
    else: # Battery
        if 90 <= percentage <= 100:
            icon = "􀛨" # Full battery
            label_color = "0xffffffff"
        elif 60 <= percentage <= 89:
            icon = "􀺸" # 75% battery
            label_color = "0xffffffff"
        elif 30 <= percentage <= 59:
            icon = "􀺶" # 50% battery
            label_color = "0xffffcc66" # Yellow
        elif 10 <= percentage <= 29:
            icon = "􀛩" # 25% battery
            label_color = "0xffff9933" # Orange
        else: # 0-9%
            icon = "􀛪" # Empty battery
            label_color = "0xffff6666" # Red
        
        # Remaining time is for battery, not AC
        if remaining and remaining != "0:00":
            remaining_indicator = remaining
            align = "center" # Center align if showing time
        else:
            align = "left" # Default align if no remaining time

    return icon, label_color, remaining_indicator, align


def main():
    state = battery_state()
    if state is None:
        print("Could not get battery state.", file=sys.stderr)
        return

    name = os.environ.get("NAME", "")
    if not name:
        print("NAME environment variable not set.", file=sys.stderr)
        return

    percentage_str = state["percentage"]
    percentage = int(percentage_str)
    
    icon, label_color, remaining_indicator, align = get_battery_icon_and_color(state)

    percentage_label = f"{percentage_str}%"

    # Update the main battery item with icon and percentage
    run_sketchybar_command("--set", name, f"icon={icon}", f"label={percentage_label}", f"label_color={label_color}", f"label_align={align}")

    # Update the status item (often used for remaining time or specific icons)
    status_item_name = f"{name}.status"
    if remaining_indicator:
        # If there's a remaining indicator (like time or "not charging" icon), set it
        run_sketchybar_command("--set", status_item_name, f"label={remaining_indicator}", f"label_color={label_color}", f"label_align={align}")
    else:
        # Clear the status item label if no indicator is needed, or set to empty
        # This might depend on how the .status item is configured in items/battery.py
        # For now, we'll clear it as a safe default to ensure no stale data shows.
        run_sketchybar_command("--set", status_item_name, "label=")

    # Handle special cases for when AC is plugged in and not charging, or fully charged.
    # This logic might need refinement based on the exact desired behavior and item config.
    if state["use_ac"] and state["not_charging"]:
        # Specific setting for AC power and not charging
        run_sketchybar_command("--set", name, "label_color=0xff00aaff") # Ensure blue for AC
    elif percentage == 100 and not state["use_ac"]:
        # If fully charged on battery, ensure correct icon/color (already handled by get_battery_icon_and_color)
        pass
    elif not state["use_ac"] and remaining_indicator == "􀊅":
        # If on battery and showing "not charging" indicator, ensure correct color
        run_sketchybar_command("--set", status_item_name, "label_color=0xffff6666") # Red for not charging warning

if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError) as error:
        print(f"battery plugin: {error}", file=sys.stderr)
        sys.exit(1)
