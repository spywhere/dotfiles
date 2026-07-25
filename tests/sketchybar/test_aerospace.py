"""Regression tests for the aerospace SketchyBar plugin's state-diffing.

These tests do not require a running SketchyBar or the aerospace CLI. They
mock ``subprocess.run`` (for aerospace) and ``SketchyBar._execute`` (for
sketchybar) and assert which properties the plugin emits on re-render.
"""

import importlib.util
import json
import os
import subprocess
import unittest
from unittest.mock import patch

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
PLUGIN_PATH = os.path.join(
    REPO_ROOT, "configs", "sketchybar", "plugins", "aerospace.py"
)
CONFIG_DIR = os.path.join(REPO_ROOT, "configs", "sketchybar")


def _load_module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


# Load the aerospace plugin (which imports sketchybar_api as a side effect).
aerospace_module = _load_module("aerospace_for_test", PLUGIN_PATH)
SketchyBar = aerospace_module.SketchyBar


def _make_aerospace_run(focused, records, windows_by_ws):
    """Return a fake ``subprocess.run`` that dispatches aerospace CLI calls."""

    def fake_run(cmd, *args, **kwargs):
        if (
            cmd[:3] == ["aerospace", "list-workspaces", "--all"]
            and "--json" in cmd
        ):
            return subprocess.CompletedProcess(
                args=cmd, returncode=0, stdout=json.dumps(records), stderr=""
            )
        if cmd[:3] == ["aerospace", "list-workspaces", "--all"]:
            names = "\n".join(r["workspace"] for r in records)
            return subprocess.CompletedProcess(
                args=cmd, returncode=0, stdout=names, stderr=""
            )
        if cmd[:3] == ["aerospace", "list-workspaces", "--focused"]:
            return subprocess.CompletedProcess(
                args=cmd, returncode=0, stdout=focused, stderr=""
            )
        if cmd[:3] == ["aerospace", "list-windows", "--workspace"]:
            ws = cmd[3]
            wins = windows_by_ws.get(ws, [])
            return subprocess.CompletedProcess(
                args=cmd, returncode=0, stdout=json.dumps(wins), stderr=""
            )
        if cmd[:2] == ["aerospace", "list-modes", "--current"]:
            return subprocess.CompletedProcess(
                args=cmd, returncode=0, stdout="main", stderr=""
            )
        raise AssertionError("unexpected aerospace cmd: {}".format(cmd))

    return fake_run


def _make_execute(captured, query_state=None, query_raises=False):
    """Return a fake ``SketchyBar._execute`` that captures argv."""

    def fake_execute(args, check=True, **kwargs):
        captured.append(list(args))
        if args and args[0] == "--query":
            if query_raises:
                raise SketchyBar.Error("query failed (item missing)")
            stdout = (
                json.dumps(query_state) if query_state is not None else "{}"
            )
            return subprocess.CompletedProcess(
                args=["sketchybar"] + list(args),
                returncode=0,
                stdout=stdout,
                stderr="",
            )
        return subprocess.CompletedProcess(
            args=["sketchybar"] + list(args),
            returncode=0,
            stdout="",
            stderr="",
        )

    return fake_execute


def _extract_set_props(captured):
    """Extract key=value pairs from the animated --set call, if any."""
    for argv in captured:
        if "--animate" in argv and "--set" in argv:
            set_idx = argv.index("--set")
            pairs = argv[set_idx + 2:]  # skip "--set" and the item id
            props = {}
            for pair in pairs:
                if "=" in pair:
                    key, value = pair.split("=", 1)
                    props[key] = value
            return props
    return None


def _run_update(
    query_state, focused, records, windows_by_ws, query_raises=False
):
    captured = []
    execute = _make_execute(captured, query_state, query_raises)
    run = _make_aerospace_run(focused, records, windows_by_ws)
    with patch("subprocess.run", run):
        bar = SketchyBar(executable="sketchybar", config_dir=CONFIG_DIR)
        # Instance-attribute override (not a class patch) so the fake is
        # called with the argv list directly, not bound as a method with
        # ``self`` prepended.
        bar._execute = execute
        aerospace_module.update_windows_for_workspace(
            bar, "aerospace.workspace.3", "3"
        )
    return captured


# Canned query states -------------------------------------------------------

# Unfocused ws 3 with one qutebrowser window, visible on display 1.
STATE_UNFOCUSED_QB = {
    "icon": {
        "color": {"alpha": "0.2"},
        "value": "3",
        "width": 20,
        "padding_right": 4,
        "padding_left": 8,
    },
    "label": {
        "value": ":qute_browser:",
        "width": 29,
        "padding_left": 4,
        "padding_right": 8,
        "color": {"alpha": "0.2"},
        "font": "sketchybar-app-font:Regular:16",
    },
    "geometry": {"display": "1"},
}

# Focused ws 3 with one qutebrowser window.
STATE_FOCUSED_QB = {
    "icon": {
        "color": {"alpha": "1"},
        "value": "3",
        "width": 20,
        "padding_right": 4,
        "padding_left": 8,
    },
    "label": {
        "value": ":qute_browser:",
        "width": 29,
        "padding_left": 4,
        "padding_right": 8,
        "color": {"alpha": "1"},
        "font": "sketchybar-app-font:Regular:16",
    },
    "geometry": {"display": "1"},
}

# Empty label, collapsed paddings (no windows), not focused.
STATE_EMPTY = {
    "icon": {
        "color": {"alpha": "0.2"},
        "value": "3",
        "width": 13,
        "padding_right": 0,
        "padding_left": 8,
    },
    "label": {
        "value": "",
        "width": 9,
        "padding_left": 0,
        "padding_right": 8,
        "color": {"alpha": "0.2"},
        "font": "sketchybar-app-font:Regular:16",
    },
    "geometry": {"display": "1"},
}

# Ghostty label, expanded paddings, not focused.
STATE_GHOSTTY = {
    "icon": {
        "color": {"alpha": "0.2"},
        "value": "3",
        "width": 30,
        "padding_right": 4,
        "padding_left": 8,
    },
    "label": {
        "value": ":ghostty:",
        "width": 30,
        "padding_left": 4,
        "padding_right": 8,
        "color": {"alpha": "0.2"},
        "font": "sketchybar-app-font:Regular:16",
    },
    "geometry": {"display": "1"},
}


class UpdateWindowsForWorkspaceTests(unittest.TestCase):
    def _records(self, visible, display):
        return [
            {
                "workspace": "3",
                "workspace-is-visible": visible,
                "monitor-appkit-nsscreen-screens-id": display,
            }
        ]

    # Scenario 1: workspace switch — becomes focused (only color changes).
    def test_becomes_focused_only_color_changes(self):
        records = self._records(visible=True, display="1")
        windows = {"3": [{"app-name": "qutebrowser", "window-id": 100}]}
        captured = _run_update(
            STATE_UNFOCUSED_QB,
            focused="3",
            records=records,
            windows_by_ws=windows,
        )
        props = _extract_set_props(captured)
        self.assertIsNotNone(props, "expected an animated --set call")
        self.assertEqual(
            set(props.keys()), {"icon.color.alpha", "label.color.alpha"}
        )
        self.assertEqual(props["icon.color.alpha"], "1")
        self.assertEqual(props["label.color.alpha"], "1")
        forbidden = [
            "width",
            "icon.width",
            "label.width",
            "label",
            "display",
            "icon",
            "icon.padding_right",
            "icon.padding_left",
            "label.padding_left",
            "label.font",
            "label.padding_right",
        ]
        for key in forbidden:
            self.assertNotIn(key, props)

    # Scenario 2: workspace switch — loses focus (only color changes).
    def test_loses_focus_only_color_changes(self):
        records = self._records(visible=False, display="1")
        windows = {"3": [{"app-name": "qutebrowser", "window-id": 100}]}
        captured = _run_update(
            STATE_FOCUSED_QB,
            focused="5",
            records=records,
            windows_by_ws=windows,
        )
        props = _extract_set_props(captured)
        self.assertIsNotNone(props)
        self.assertEqual(
            set(props.keys()), {"icon.color.alpha", "label.color.alpha"}
        )
        self.assertEqual(props["icon.color.alpha"], "0.2")
        self.assertEqual(props["label.color.alpha"], "0.2")

    # Scenario 3: window opened (label changes, color does not).
    def test_window_opened_label_changes(self):
        records = self._records(visible=False, display="1")
        windows = {"3": [{"app-name": "Ghostty", "window-id": 200}]}
        captured = _run_update(
            STATE_EMPTY,
            focused="5",
            records=records,
            windows_by_ws=windows,
        )
        props = _extract_set_props(captured)
        self.assertIsNotNone(props)
        self.assertEqual(
            set(props.keys()),
            {
                "label",
                "icon.padding_right",
                "label.padding_left",
                "width",
                "icon.width",
                "label.width",
            },
        )
        self.assertEqual(props["label"], ":ghostty:")
        self.assertEqual(props["icon.padding_right"], "4")
        self.assertEqual(props["label.padding_left"], "4")
        self.assertEqual(props["width"], "dynamic")
        self.assertEqual(props["icon.width"], "dynamic")
        self.assertEqual(props["label.width"], "dynamic")
        forbidden = [
            "icon.color.alpha",
            "label.color.alpha",
            "display",
            "icon",
            "icon.padding_left",
            "label.font",
            "label.padding_right",
        ]
        for key in forbidden:
            self.assertNotIn(key, props)

    # Scenario 4: window closed (label changes back).
    def test_window_closed_label_changes_back(self):
        records = self._records(visible=False, display="1")
        windows = {"3": []}
        captured = _run_update(
            STATE_GHOSTTY,
            focused="5",
            records=records,
            windows_by_ws=windows,
        )
        props = _extract_set_props(captured)
        self.assertIsNotNone(props)
        self.assertEqual(
            set(props.keys()),
            {
                "label",
                "icon.padding_right",
                "label.padding_left",
                "width",
                "icon.width",
                "label.width",
            },
        )
        self.assertEqual(props["label"], "")
        self.assertEqual(props["icon.padding_right"], "0")
        self.assertEqual(props["label.padding_left"], "0")
        self.assertEqual(props["width"], "dynamic")
        self.assertEqual(props["icon.width"], "dynamic")
        self.assertEqual(props["label.width"], "dynamic")

    # Scenario 5: nothing changed — no update emitted.
    def test_nothing_changed_emits_nothing(self):
        records = self._records(visible=True, display="1")
        windows = {"3": [{"app-name": "qutebrowser", "window-id": 100}]}
        captured = _run_update(
            STATE_FOCUSED_QB,
            focused="3",
            records=records,
            windows_by_ws=windows,
        )
        self.assertIsNone(_extract_set_props(captured))
        for argv in captured:
            self.assertNotIn("--set", argv)
            self.assertNotIn("--animate", argv)

    # Scenario 6: initial creation (query fails) — full 14-property set.
    def test_initial_creation_emits_full_set(self):
        records = self._records(visible=True, display="1")
        windows = {"3": [{"app-name": "qutebrowser", "window-id": 100}]}
        captured = _run_update(
            None,
            focused="3",
            records=records,
            windows_by_ws=windows,
            query_raises=True,
        )
        props = _extract_set_props(captured)
        self.assertIsNotNone(props)
        expected_keys = {
            "width",
            "icon.width",
            "label.width",
            "display",
            "icon.padding_left",
            "icon.padding_right",
            "icon",
            "icon.color.alpha",
            "label",
            "label.font",
            "label.padding_left",
            "label.padding_right",
            "label.color.alpha",
        }
        self.assertEqual(set(props.keys()), expected_keys)
        self.assertEqual(len(props), 13)
        self.assertEqual(props["icon"], "3")
        self.assertEqual(props["label"], ":qute_browser:")
        self.assertEqual(props["display"], "1")
        self.assertEqual(props["icon.color.alpha"], "1")
        self.assertEqual(props["label.color.alpha"], "1")
        self.assertEqual(props["icon.padding_right"], "4")
        self.assertEqual(props["label.padding_left"], "4")
        self.assertEqual(props["icon.padding_left"], "8")
        self.assertEqual(props["label.padding_right"], "8")
        self.assertEqual(props["label.font"], "sketchybar-app-font:Regular:16")
        self.assertEqual(props["width"], "dynamic")
        self.assertEqual(props["icon.width"], "dynamic")
        self.assertEqual(props["label.width"], "dynamic")

    # Scenario 7: display changed (workspace moved to another monitor).
    def test_display_changed_emits_only_display(self):
        records = self._records(visible=True, display="2")
        windows = {"3": [{"app-name": "qutebrowser", "window-id": 100}]}
        captured = _run_update(
            STATE_FOCUSED_QB,
            focused="3",
            records=records,
            windows_by_ws=windows,
        )
        props = _extract_set_props(captured)
        self.assertIsNotNone(props)
        self.assertEqual(set(props.keys()), {"display"})
        self.assertEqual(props["display"], "2")


if __name__ == "__main__":
    unittest.main()
