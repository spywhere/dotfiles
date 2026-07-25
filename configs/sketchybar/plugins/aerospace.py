#!/usr/bin/env python3

"""SketchyBar aerospace plugin — syncs workspace items from the aerospace CLI."""

import json
import os
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
LIB_DIR = os.path.join(os.path.dirname(SCRIPT_DIR), "lib")
if LIB_DIR not in sys.path:
    sys.path.insert(0, LIB_DIR)

from sketchybar_api import SketchyBar

# Load icon_map.json once; degrade gracefully if missing/malformed.
try:
    with open(os.path.join(SCRIPT_DIR, "icon_map.json"), "r", encoding="utf-8") as fh:
        _ICON_MAP = json.load(fh)
except (OSError, ValueError):
    _ICON_MAP = []


def icon_for(app):
    """Return the SF Symbol icon for an app name, or ':default:' if unknown."""
    for entry in _ICON_MAP:
        app_names = entry.get("appNames")
        if app_names and app in app_names:
            icon = entry.get("iconName")
            if icon:
                return icon
    return ":default:"


def _run(cmd):
    """Run an external command, returning CompletedProcess (check=True, capture stdout, text)."""
    return subprocess.run(cmd, check=True, capture_output=True, text=True)


def _window_sort_key(window_id):
    try:
        return (0, int(window_id))
    except (TypeError, ValueError):
        return (1, str(window_id))


def list_workspaces_all():
    """Plain-text workspace names."""
    result = _run(["aerospace", "list-workspaces", "--all"])
    return result.stdout.split()


def list_workspaces_json(fmt):
    """List of workspace record dicts."""
    result = _run(
        ["aerospace", "list-workspaces", "--all", "--json", "--format", fmt]
    )
    try:
        return json.loads(result.stdout)
    except ValueError:
        return []


def list_focused_workspace():
    """Focused workspace name."""
    result = _run(
        ["aerospace", "list-workspaces", "--focused", "--format", "%{workspace}"]
    )
    return result.stdout.strip()


def list_windows_json(ws, fmt):
    """Windows in a workspace, sorted by window-id (type-agnostic)."""
    result = _run(
        ["aerospace", "list-windows", "--workspace", ws, "--json", "--format", fmt]
    )
    try:
        windows = json.loads(result.stdout)
    except ValueError:
        return []
    return sorted(windows, key=lambda w: _window_sort_key(w.get("window-id")))


def update_mode(bar, name):
    mode = _run(["aerospace", "list-modes", "--current"]).stdout.strip()
    drawing = "on" if mode == "service" else "off"
    bar.item(name).set({"drawing": drawing})


def update_windows_for_workspace(bar, name, ws):
    focused = list_focused_workspace()
    records = list_workspaces_json(
        "%{workspace}%{workspace-is-visible}%{monitor-appkit-nsscreen-screens-id}"
    )
    record = next((r for r in records if r.get("workspace") == ws), None)
    if record is None:
        return
    visible = bool(record.get("workspace-is-visible", False))
    display = record.get("monitor-appkit-nsscreen-screens-id")
    if display is None or display is False:
        display = "active"
    windows = list_windows_json(ws, "%{app-name}%{window-id}")
    icons = "".join(icon_for(w.get("app-name", "")) for w in windows)
    icon_padding = 4 if icons else 0
    if ws == focused:
        color_alpha = "1"
    elif visible:
        color_alpha = "0.4"
    else:
        color_alpha = "0.2"
    item = bar.item(name)
    item.animate("sin", 10).set(
        {
            "width": "dynamic",
            "icon.width": "dynamic",
            "label.width": "dynamic",
            "display": display,
            "icon.padding_left": 8,
            "icon.padding_right": icon_padding,
            "icon": ws,
            "icon.color.alpha": color_alpha,
            "label": icons,
            "label.font": "sketchybar-app-font:Regular:16",
            "label.padding_left": icon_padding,
            "label.padding_right": 8,
            "label.color.alpha": color_alpha,
        }
    )


def reconcile(bar, name):
    records = list_workspaces_json("%{workspace}%{monitor-appkit-nsscreen-screens-id}")
    plugin = bar.python_plugin(os.path.join("plugins", "aerospace.py"))
    last_id = ""
    update_bracket = False
    for record in records:
        workspace = record.get("workspace")
        display = record.get("monitor-appkit-nsscreen-screens-id")
        if display is None or display is False:
            display = "active"
        item_id = "{}.workspace.{}".format(name, workspace)
        exists = True
        try:
            bar.item(item_id).query()
        except SketchyBar.QueryError:
            exists = False
            # bar.item() registered a binding for the probe; drop it so
            # bar.add() below can register the real item cleanly.
            bar._items.pop(item_id, None)
        if not exists:
            item = bar.add(SketchyBar.Item(item_id), position="left")
            item.set(
                {
                    "icon.width": 0,
                    "label.width": 0,
                    "display": display,
                    "script": plugin,
                    "click_script": "aerospace workspace {}".format(workspace),
                }
            )
            item.subscribe(
                "aerospace_workspace_change",
                "space_windows_change",
                "display_change",
                "system_woke",
                "front_app_switched",
            )
            if last_id:
                bar.move(item_id, after=last_id)
            update_bracket = True
            update_windows_for_workspace(bar, item_id, workspace)
        # Always update last_id (replicates the shell's commented-out display comparison).
        last_id = item_id
    if update_bracket:
        bracket_id = "{}.bar".format(name)
        try:
            bar.remove(bracket_id)
        except SketchyBar.Error:
            pass
        bar.add_bracket(bracket_id, "/{}.workspace.*/".format(name))
        bar.item(bracket_id).set(
            {
                "background.color": "0x20ffffff",
                "background.corner_radius": 25,
                "background.height": 25,
            }
        )


def main():
    name = os.environ.get("NAME")
    if not name:
        if len(sys.argv) > 1:
            name = sys.argv[1]
        else:
            return
    bar = SketchyBar()
    try:
        if name.endswith(".mode"):
            update_mode(bar, name)
        elif ".workspace." in name:
            current = name.rsplit(".workspace.", 1)[-1]
            if current not in list_workspaces_all():
                bar.remove(name)
                return
            sender = os.environ.get("SENDER", "")
            if sender == "aerospace_workspace_change":
                # Only the prev and focused workspaces change on a workspace
                # switch; other workspace items skip to avoid mass re-render.
                focused = os.environ.get("FOCUSED_WORKSPACE", "")
                prev = os.environ.get("PREV_WORKSPACE", "")
                if current != focused and current != prev:
                    return
            elif sender == "front_app_switched":
                # Only the focused workspace's window list is affected by a
                # front app switch.
                focused = list_focused_workspace()
                if current != focused:
                    return
            # space_windows_change, display_change, system_woke, and unknown/
            # absent sender: fall through to a full update.
            update_windows_for_workspace(bar, name, current)
        else:
            reconcile(bar, name)
    except FileNotFoundError:
        # aerospace CLI not installed — silent, matches shell.
        return
    except subprocess.CalledProcessError as error:
        print("aerospace plugin: {}".format(error), file=sys.stderr)
    except SketchyBar.Error as error:
        print("aerospace plugin: {}".format(error), file=sys.stderr)


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError) as error:
        print("aerospace plugin: {}".format(error), file=sys.stderr)
        sys.exit(1)
