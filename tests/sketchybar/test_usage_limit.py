"""Focused refresh and click behavior tests for the SketchyBar usage item."""

import datetime
import json
import os
import re
import subprocess
import tempfile
import time
import unittest


REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
PLUGIN_PATH = os.path.join(
    REPO_ROOT, "configs", "sketchybar", "plugins", "usage_limit.sh"
)
ITEM_PATH = os.path.join(
    REPO_ROOT, "configs", "sketchybar", "items", "usage_limit.sh"
)


class UsageLimitTests(unittest.TestCase):
    def _run_plugin(self, usage=None, name="usage", sender="routine",
                    codexbar_status=0):
        with tempfile.TemporaryDirectory() as directory:
            codexbar_log = os.path.join(directory, "codexbar.log")
            sketchybar_log = os.path.join(directory, "sketchybar.log")
            scripts = {
                "codexbar": (
                    "#!/bin/sh\nprintf '%s\\n' \"$@\" >> \"$CODEXBAR_LOG\"\n"
                    "printf '%s' \"$CODEXBAR_USAGE_JSON\"\nexit \"$CODEXBAR_STATUS\"\n"
                ),
                "defaults": "#!/bin/sh\nexit 1\n",
                "sketchybar": (
                    "#!/bin/sh\nprintf '%s\\n' \"$@\" >> \"$SKETCHYBAR_LOG\"\n"
                    "printf '%s\\n' \"$@\"\n"
                ),
            }
            for script_name, contents in scripts.items():
                path = os.path.join(directory, script_name)
                with open(path, "w") as file_handle:
                    file_handle.write(contents)
                os.chmod(path, 0o755)

            environment = os.environ.copy()
            environment.update({
                "CODEXBAR_LOG": codexbar_log,
                "SKETCHYBAR_LOG": sketchybar_log,
                "CODEXBAR_STATUS": str(codexbar_status),
                "CODEXBAR_USAGE_JSON": json.dumps(usage),
                "NAME": name,
                "SENDER": sender,
                "PATH": directory + os.pathsep + environment["PATH"],
            })
            result = subprocess.run(
                ["/bin/bash", PLUGIN_PATH], check=True, capture_output=True,
                env=environment, text=True,
            )
            if os.path.exists(codexbar_log):
                with open(codexbar_log) as file_handle:
                    codexbar_calls = file_handle.read()
            else:
                codexbar_calls = ""
            if os.path.exists(sketchybar_log):
                with open(sketchybar_log) as file_handle:
                    sketchybar_calls = file_handle.read()
            else:
                sketchybar_calls = ""
            return result.stdout, codexbar_calls, sketchybar_calls

    @staticmethod
    def _usage(provider="codex", used=25, resets_at="broken", secondary=None):
        usage = {"primary": {"usedPercent": used, "resetsAt": resets_at}}
        if secondary is not None:
            usage["secondary"] = secondary
        return [{"provider": provider, "usage": usage}]

    def test_routine_refresh_fetches_once_caches_and_builds_hidden_popup(self):
        output, codexbar_calls, _ = self._run_plugin(self._usage())

        self.assertEqual("usage\n--json\n", codexbar_calls)
        self.assertIn("--set\nusage\nicon=", output)
        self.assertIn('"usedPercent":25', output)
        self.assertIn('"resetCompact":"unavailable"', output)
        self.assertNotIn("resetsAt", output)
        self.assertIn("--add\nitem\nusage.popup.0\npopup.usage", output)
        self.assertIn("--add\nslider\nusage.popup.0.primary\npopup.usage", output)
        self.assertIn("popup.drawing=off", output)
        cache_write = output.index("--set\nusage\nicon=")
        persistent_update = output.index("--set\nusage\ndrawing=on")
        persistent_command = output[persistent_update:output.index(
            "--set\nusage.primary", persistent_update
        )]
        popup_reconciliation = output.index(
            "--set\nusage\npopup.drawing=off\n--remove"
        )
        popup_item_add = output.index("--add\nitem\nusage.popup.0\npopup.usage")
        popup_slider_add = output.index(
            "--add\nslider\nusage.popup.0.primary\npopup.usage"
        )
        self.assertLess(cache_write, persistent_update)
        self.assertLess(cache_write, popup_reconciliation)
        self.assertLess(cache_write, popup_item_add)
        self.assertLess(cache_write, popup_slider_add)
        self.assertNotIn("icon=", persistent_command)

    def test_click_only_toggles_prebuilt_popup(self):
        for name in ("usage", "usage.primary", "usage.secondary"):
            with self.subTest(name=name):
                output, codexbar_calls, sketchybar_calls = self._run_plugin(
                    name=name, sender="mouse.clicked"
                )

                self.assertEqual("", codexbar_calls)
                self.assertEqual(
                    "--set\nusage\npopup.drawing=toggle\n", sketchybar_calls
                )
                self.assertEqual("--set\nusage\npopup.drawing=toggle\n", output)
                self.assertNotIn("--query", output)
                self.assertNotIn("--add", output)
                self.assertNotIn("--remove", output)

    def test_successful_subsequent_refresh_removes_stale_popup_rows(self):
        initial_output, _, _ = self._run_plugin(self._usage(
            provider="claude", used=50,
            secondary={"usedPercent": 75, "resetsAt": "broken"},
        ))
        output, _, _ = self._run_plugin(self._usage(provider="claude", used=50))

        self.assertIn("usage.popup.0.secondary", initial_output)
        self.assertIn("--remove\n/usage\\.popup\\..*/", output)
        self.assertNotIn("--add\nslider\nusage.popup.0.secondary", output)
        self.assertIn("label=Claude", output)

    def test_failed_refresh_preserves_last_good_snapshot(self):
        good_output, _, _ = self._run_plugin(self._usage())
        failed_output, codexbar_calls, _ = self._run_plugin(
            None, codexbar_status=1
        )

        self.assertIn("usage.popup.0.primary", good_output)
        self.assertEqual("usage\n--json\n", codexbar_calls)
        self.assertEqual("", failed_output)

    def test_only_parent_owns_routine_refresh(self):
        with open(ITEM_PATH) as file_handle:
            item_config = file_handle.read()
        with open(PLUGIN_PATH) as file_handle:
            plugin = file_handle.read()

        self.assertRegex(item_config, r"--set usage \\\n\s+drawing=off \\\n\s+update_freq=300")
        row_config = item_config.split("--add item usage.primary", 1)[1]
        self.assertNotIn("update_freq", row_config)
        self.assertIn("--subscribe usage.primary mouse.clicked", row_config)
        self.assertIn("--subscribe usage.secondary mouse.clicked", row_config)
        self.assertIn('elif test "$NAME" = "usage"; then', plugin)
        self.assertNotIn("LOCK_DIR", plugin)
        self.assertNotIn("ps -o", plugin)

    def test_persistent_rows_render_single_limit_without_newlines(self):
        output, _, _ = self._run_plugin(self._usage(used=25))

        self.assertIn("--set\nusage.primary\ndrawing=on\nlabel=75%", output)
        self.assertIn(
            "--set\nusage.secondary\ndrawing=on\nlabel=unavailable",
            output,
        )
        self.assertNotIn("label=75%\nunavailable", output)

    def test_persistent_rows_render_two_limits(self):
        output, _, _ = self._run_plugin(self._usage(
            used=25, secondary={"usedPercent": 50, "resetsAt": "broken"}
        ))

        self.assertIn(
            "--set\nusage.primary\ndrawing=on\nlabel=75% unavailable",
            output,
        )
        self.assertIn(
            "--set\nusage.secondary\ndrawing=on\nlabel=50% unavailable",
            output,
        )

    def test_persistent_item_layout_has_provider_and_two_stacked_rows(self):
        with open(ITEM_PATH) as file_handle:
            item_config = file_handle.read()

        self.assertIn("--add item usage right", item_config)
        self.assertIn("--add item usage.primary right", item_config)
        self.assertIn("--add item usage.secondary right", item_config)
        self.assertEqual(3, item_config.count("--add item usage"))
        self.assertNotIn("usage.provider", item_config)
        self.assertNotIn("usage.quotas", item_config)
        self.assertIn("--move usage.primary after usage", item_config)
        self.assertIn("--move usage.secondary after usage.primary", item_config)
        self.assertIn("--move usage after usage.secondary", item_config)
        self.assertIn("label.y_offset=5", item_config)
        self.assertIn("label.y_offset=-5", item_config)
        self.assertIn("label.y_offset=0", item_config)
        self.assertIn("label.font=\"SF Pro:Semibold:14\"", item_config)
        self.assertRegex(item_config, re.compile(
            r"--set usage \\\n\s+drawing=off.*?label\.font=\"SF Pro:Semibold:14\" \\\n"
            r"\s+label\.y_offset=0 \\\n\s+label\.align=left \\\n"
            r"\s+label\.padding_left=0 \\\n\s+label\.padding_right=6",
            re.DOTALL,
        ))
        self.assertRegex(item_config, re.compile(
            r"--set usage\.primary \\\n\s+drawing=off.*?label\.font\.size=8 \\\n"
            r"\s+label\.y_offset=5 \\\n\s+label\.width=70 \\\n"
            r"\s+label\.align=left \\\n\s+label\.padding_left=0 \\\n"
            r"\s+label\.padding_right=0 \\\n\s+width=0",
            re.DOTALL,
        ))
        self.assertRegex(item_config, re.compile(
            r"--set usage\.secondary \\\n\s+drawing=off.*?label\.font\.size=8 \\\n"
            r"\s+label\.y_offset=-5 \\\n\s+label\.width=70 \\\n"
            r"\s+label\.align=left \\\n\s+label\.padding_left=0 \\\n"
            r"\s+label\.padding_right=0",
            re.DOTALL,
        ))
        secondary_config = item_config.split("--set usage.secondary", 1)[1]
        self.assertNotRegex(secondary_config, r"(?:^|\s)width=0(?:\s|$)")
        self.assertEqual(3, item_config.count("label.padding_left=0"))
        self.assertEqual(2, item_config.count("label.padding_right=0"))
        self.assertEqual(1, item_config.count("label.padding_right=6"))

    def test_persistent_rows_render_secondary_only_limit(self):
        output, _, _ = self._run_plugin([{
            "provider": "codex",
            "usage": {"secondary": {"usedPercent": 50, "resetsAt": "broken"}},
        }])

        self.assertIn("--set\nusage.primary\ndrawing=on\nlabel=50%", output)
        self.assertIn(
            "--set\nusage.secondary\ndrawing=on\nlabel=unavailable", output,
        )

    def test_z_timestamp_has_relative_compact_reset(self):
        reset_at = datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(
            days=2, hours=3, minutes=4
        )
        output, _, _ = self._run_plugin(self._usage(
            resets_at=reset_at.strftime("%Y-%m-%dT%H:%M:%SZ")
        ))
        compact_reset = next(
            line for line in output.splitlines() if "label=" in line
            and re.search(r"label=\d+d\d+h\d+m", line)
        )
        match = re.search(r"label=(\d+)d(\d+)h(\d+)m", compact_reset)
        self.assertIsNotNone(match)
        rendered_minutes = (
            int(match.group(1)) * 24 * 60 + int(match.group(2)) * 60
            + int(match.group(3))
        )
        expected_minutes = int((reset_at.timestamp() - time.time()) // 60)
        self.assertLessEqual(abs(rendered_minutes - expected_minutes), 1)


if __name__ == "__main__":
    unittest.main()
