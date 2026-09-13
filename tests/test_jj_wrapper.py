import importlib.util
import json
import os
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
WRAPPER = PROJECT_ROOT / "binaries" / "jj"
SPEC = importlib.util.spec_from_file_location(
    "jj_hooks_test_module", PROJECT_ROOT / "binaries" / "_jj_hooks.py"
)
HOOKS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(HOOKS)


FAKE_JJ = r'''#!/usr/bin/env python3
import json
import os
import sys

args = sys.argv[1:]
with open(os.environ["FAKE_JJ_LOG"], "a") as handle:
    handle.write(json.dumps(args) + "\n")

def output(value):
    sys.stdout.buffer.write(value)

if "workspace" in args and "root" in args:
    output(os.fsencode(os.environ["FAKE_ROOT"]) + b"\n")
elif "git" in args and "root" in args:
    output(os.fsencode(os.environ["FAKE_GIT_DIR"]) + b"\n")
elif "git" in args and "push" in args and "--dry-run" in args:
    output(os.environ.get("FAKE_PUSH_PLAN", "").encode())
elif "op" in args and "log" in args:
    output(os.environ.get("FAKE_OPERATION_ID", "operation-before-split").encode())
    output(b"\0")
elif "diff" in args:
    for name in json.loads(os.environ.get("FAKE_SELECTED_FILES", "[]")):
        output(os.fsencode(name) + b"\0")
elif "log" in args:
    template = args[args.index("-T") + 1]
    if "diff.files" in template:
        for name in json.loads(os.environ.get("FAKE_FILES", "[]")):
            output(os.fsencode(name) + b"\0")
    elif "empty" in template:
        output(os.environ.get("FAKE_CHANGE_ID", "changeid").encode())
        output(b"\0true\0")
    elif "change_id" in template:
        revision = args[args.index("-r") + 1]
        if revision == "all()":
            with open(os.environ["FAKE_JJ_LOG"]) as handle:
                split_done = any("split" in json.loads(line) for line in handle)
            key = "FAKE_ALL_CHANGE_IDS_AFTER" if split_done else "FAKE_ALL_CHANGE_IDS"
            for change_id in json.loads(os.environ.get(key, '["existing"]')):
                output(change_id.encode() + b"\0")
        else:
            output(os.environ.get("FAKE_CHANGE_ID", "changeid").encode() + b"\0")
    elif "commit_id" in template:
        revision = args[args.index("-r") + 1]
        if revision.startswith("parents("):
            value = os.environ.get("FAKE_PARENT_ID", "111111111111")
        elif (revision == "@"
              and os.environ.get("FAKE_COMMIT_ID_AFTER_HOOK")
              and os.path.exists(os.environ["FAKE_CHECKER_LOG"])
              and any(
                  call[call.index("--hook-stage") + 1]
                  == os.environ.get("FAKE_AFTER_HOOK_STAGE", "pre-commit")
                  for call in (
                      json.loads(line) for line in
                      open(os.environ["FAKE_CHECKER_LOG"])
                  )
              )):
            value = os.environ["FAKE_COMMIT_ID_AFTER_HOOK"]
        else:
            value = os.environ.get("FAKE_COMMIT_ID", "222222222222")
        output(value.encode() + b"\0")
    elif template == "description":
        output(os.environ.get("FAKE_DESCRIPTION", "test: message").encode())

actual = None
for candidate in ("commit", "describe", "split", "status"):
    if candidate in args:
        actual = candidate
        break
if "git" in args and "push" in args and "--dry-run" not in args:
    actual = "push"
if actual:
    sys.exit(int(os.environ.get("FAKE_{0}_EXIT".format(actual.upper()), "0")))
'''


FAKE_CHECKER = r'''#!/usr/bin/env python3
import json
import os
import sys

with open(os.environ["FAKE_CHECKER_LOG"], "a") as handle:
    handle.write(json.dumps(sys.argv[1:]) + "\n")
stage = sys.argv[sys.argv.index("--hook-stage") + 1].replace("-", "_").upper()
exit_code = os.environ.get(
    "FAKE_CHECKER_{0}_EXIT".format(stage),
    os.environ.get("FAKE_CHECKER_EXIT", "0"),
)
sys.exit(int(exit_code))
'''


def executable(path, content):
    path.write_text(content)
    path.chmod(path.stat().st_mode | stat.S_IXUSR)


def read_log(path):
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text().splitlines()]


class MessageGitMarkerTest(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        self.message = self.root / "message"
        self.message.write_text("test: message\n")
        self.env = {"GIT_DIR": str(self.root / "store")}

    def test_marker_and_default_message_are_removed_after_exception(self):
        marker = self.root / ".git"
        with self.assertRaises(RuntimeError):
            with HOOKS.message_git_marker(
                    str(self.root), self.env, str(self.message)) as default:
                self.assertEqual(Path(default).read_bytes(), self.message.read_bytes())
                self.assertEqual(marker.read_text(),
                                 "gitdir: {0}\n".format(Path(default).parent))
                raise RuntimeError("hook interrupted")
        self.assertFalse(marker.exists())
        self.assertFalse(Path(default).exists())

    def test_existing_git_directory_file_and_symlink_are_untouched(self):
        marker = self.root / ".git"
        for kind in ("directory", "file", "symlink"):
            with self.subTest(kind=kind):
                if kind == "directory":
                    marker.mkdir()
                elif kind == "file":
                    marker.write_text("gitdir: original\n")
                else:
                    marker.symlink_to(self.root / "missing-store")
                before = marker.lstat()
                with HOOKS.message_git_marker(
                        str(self.root), self.env, str(self.message)) as default:
                    self.assertIsNone(default)
                self.assertEqual(marker.lstat().st_ino, before.st_ino)
                if kind == "directory":
                    marker.rmdir()
                else:
                    marker.unlink()

    def test_replaced_marker_is_not_deleted(self):
        marker = self.root / ".git"
        with HOOKS.message_git_marker(
                str(self.root), self.env, str(self.message)):
            marker.rename(self.root / "old-marker")
            marker.write_text("gitdir: replacement\n")
        self.assertEqual(marker.read_text(), "gitdir: replacement\n")


class JJWrapperTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.bin = self.base / "bin"
        self.root = self.base / "repo"
        self.git_dir = self.base / "git-store"
        self.bin.mkdir()
        self.root.mkdir()
        self.git_dir.mkdir()
        self.jj_log = self.base / "jj.log"
        self.checker_log = self.base / "checker.log"
        executable(self.bin / "jj", FAKE_JJ)
        executable(self.bin / "pre-commit", FAKE_CHECKER)
        self.env = os.environ.copy()
        self.env.update({
            "PATH": str(self.bin) + os.pathsep + self.env.get("PATH", ""),
            "FAKE_JJ_LOG": str(self.jj_log),
            "FAKE_CHECKER_LOG": str(self.checker_log),
            "FAKE_ROOT": str(self.root),
            "FAKE_GIT_DIR": str(self.git_dir),
            "FAKE_FILES": json.dumps(["plain", "space name", "line\nbreak"]),
            "FAKE_CHANGE_ID": "abcdef1234567890",
            "FAKE_COMMIT_ID": "2" * 40,
            "FAKE_PARENT_ID": "1" * 40,
            "FAKE_DESCRIPTION": "test: finalized description",
        })
        self.env.pop("JJ_HOOKS_ACTIVE", None)
        self.env.pop("JJ_HOOKS_REAL_JJ", None)

    def run_wrapper(self, *args, **kwargs):
        env = self.env.copy()
        env.update(kwargs.pop("env", {}))
        return subprocess.run(
            [str(WRAPPER)] + list(args),
            env=env,
            cwd=str(self.root),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            **kwargs
        )

    def install_git_diff_mock(self, *paths):
        git_bin = self.base / "git-bin"
        git_bin.mkdir(exist_ok=True)
        payload = b"\0".join(os.fsencode(path) for path in paths) + b"\0"
        executable(
            git_bin / "git",
            "#!/usr/bin/env python3\n"
            "import sys\n"
            "if 'diff' in sys.argv:\n"
            "    sys.stdout.buffer.write({0!r})\n".format(payload),
        )
        return str(git_bin) + os.pathsep + self.env["PATH"]

    def install_fixing_checker(self, stage, path="plain"):
        executable(
            self.bin / "pre-commit",
            "#!/usr/bin/env python3\n"
            "import json\n"
            "import os\n"
            "import sys\n"
            "with open(os.environ['FAKE_CHECKER_LOG'], 'a') as handle:\n"
            "    handle.write(json.dumps(sys.argv[1:]) + '\\n')\n"
            "current = sys.argv[sys.argv.index('--hook-stage') + 1]\n"
            "if current == {0!r}:\n"
            "    with open(os.path.join(os.environ['FAKE_ROOT'], {1!r}), "
            "'w') as handle:\n"
            "        handle.write('fixed by hook\\n')\n"
            "    sys.exit(9)\n"
            "sys.exit(0)\n".format(stage, path),
        )

    def test_other_commands_pass_through_with_arguments_and_status(self):
        result = self.run_wrapper(
            "status", "argument with spaces", "--color=always",
            env={"FAKE_STATUS_EXIT": "23"},
        )
        self.assertEqual(result.returncode, 23)
        self.assertEqual(
            read_log(self.jj_log),
            [["status", "argument with spaces", "--color=always"]],
        )

    def test_active_guard_prevents_recursive_hook_routing(self):
        result = self.run_wrapper(
            "commit", "--message", "nested",
            env={"JJ_HOOKS_ACTIVE": "1"},
        )
        self.assertEqual(result.returncode, 0)
        self.assertEqual(
            read_log(self.jj_log),
            [["commit", "--message", "nested"]],
        )
        self.assertEqual(read_log(self.checker_log), [])

    def test_message_checker_can_discover_git_and_read_default_message(self):
        (self.root / ".pre-commit-config.yaml").write_text("repos: []\n")
        executable(
            self.bin / "pre-commit",
            r'''#!/usr/bin/env python3
import json
import os
import sys
from pathlib import Path
stage = sys.argv[sys.argv.index("--hook-stage") + 1]
marker = Path(".git").read_text()
assert marker.startswith("gitdir: ")
view = Path(marker[len("gitdir: "):].strip())
message = (view / "COMMIT_EDITMSG").read_text()
assert message == os.environ["FAKE_DESCRIPTION"] + "\n"
assert os.environ["GIT_DIR"] == os.environ["FAKE_GIT_DIR"]
with open(os.environ["FAKE_CHECKER_LOG"], "a") as handle:
    handle.write(json.dumps([stage, str(view), message]) + "\n")
sys.exit(int(os.environ.get("FAKE_CHECKER_EXIT", "0")))
''',
        )
        for code in (0, 9):
            with self.subTest(code=code):
                result = self.run_wrapper(
                    "describe", "--message", "test: message",
                    env={"FAKE_CHECKER_EXIT": str(code)},
                )
                self.assertEqual(result.returncode, code, result.stderr.decode())
                self.assertFalse(os.path.lexists(self.root / ".git"))
                for stage, view, message in read_log(self.checker_log):
                    self.assertFalse(Path(view).exists())
        self.assertIn(
            ["op", "restore", "operation-before-split"], read_log(self.jj_log)
        )

    def test_prepare_checker_default_message_edits_are_applied(self):
        (self.root / ".pre-commit-config.yaml").write_text("repos: []\n")
        executable(
            self.bin / "pre-commit",
            r'''#!/usr/bin/env python3
import sys
from pathlib import Path
stage = sys.argv[sys.argv.index("--hook-stage") + 1]
if stage == "prepare-commit-msg":
    view = Path(Path(".git").read_text()[len("gitdir: "):].strip())
    (view / "COMMIT_EDITMSG").write_text("test: prepared default message\n")
''',
        )
        result = self.run_wrapper("describe", "-m", "test: original")
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertIn(
            ["describe", "--ignore-working-copy", "-r",
             self.env["FAKE_CHANGE_ID"], "--message", "test: prepared default message\n"],
            read_log(self.jj_log),
        )
        self.assertFalse((self.root / ".git").exists())

    def test_dynamic_completion_preserves_protocol_separator(self):
        result = self.run_wrapper(
            "--", "jj", "com",
            env={"COMPLETE": "zsh", "_CLAP_COMPLETE_INDEX": "1"},
        )
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertEqual(
            read_log(self.jj_log), [["--", "jj", "com"]]
        )

    def test_double_dash_bypasses_hooks_and_is_not_forwarded(self):
        (self.root / ".pre-commit-config.yaml").write_text("repos: []\n")
        result = self.run_wrapper(
            "--", "commit", "--message", "raw argument with spaces",
            env={"FAKE_CHECKER_EXIT": "9"},
        )
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertEqual(
            read_log(self.jj_log),
            [["commit", "--message", "raw argument with spaces"]],
        )
        self.assertEqual(read_log(self.checker_log), [])

    def test_pre_commit_failure_blocks_commit_and_preserves_safe_paths(self):
        (self.root / ".pre-commit-config.yaml").write_text("repos: []\n")
        result = self.run_wrapper(
            "-R", str(self.root), "commit", "--message", "test: change",
            env={"FAKE_CHECKER_EXIT": "9"},
        )
        self.assertEqual(result.returncode, 9)
        checker_calls = read_log(self.checker_log)
        self.assertEqual(len(checker_calls), 1)
        self.assertEqual(checker_calls[0][0:3], [
            "run", "--hook-stage", "pre-commit",
        ])
        files_index = checker_calls[0].index("--files")
        self.assertEqual(
            checker_calls[0][files_index + 1:],
            ["plain", "space name", "line\nbreak"],
        )
        self.assertFalse(any(
            "commit" in call and "workspace" not in call
            for call in read_log(self.jj_log)
        ))

    def test_commit_filesets_check_only_selected_changed_files(self):
        (self.root / ".pre-commit-config.yaml").write_text("repos: []\n")
        result = self.run_wrapper(
            "commit", "src", "glob:tests/**", "--message", "selected",
            env={"FAKE_SELECTED_FILES": json.dumps([
                "src/main.py", "tests/space name.py"
            ])},
        )
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        checker_calls = read_log(self.checker_log)
        self.assertEqual(
            checker_calls[0][checker_calls[0].index("--files") + 1:],
            ["src/main.py", "tests/space name.py"],
        )
        diff_calls = [call for call in read_log(self.jj_log)
                      if "diff" in call]
        separator = diff_calls[0].index("--")
        self.assertEqual(
            diff_calls[0][separator:], ["--", "src", "glob:tests/**"]
        )

    def test_commit_fileset_hook_failure_blocks_commit(self):
        (self.root / ".pre-commit-config.yaml").write_text("repos: []\n")
        result = self.run_wrapper(
            "commit", "selected", "--message", "blocked",
            env={
                "FAKE_SELECTED_FILES": json.dumps(["selected"]),
                "FAKE_CHECKER_EXIT": "9",
            },
        )
        self.assertEqual(result.returncode, 9)
        self.assertNotIn(
            ["commit", "selected", "--message", "blocked"],
            read_log(self.jj_log),
        )

    def test_interactive_commit_checks_after_selection(self):
        (self.root / ".pre-commit-config.yaml").write_text("repos: []\n")
        result = self.run_wrapper("commit", "--interactive", "--message", "selected")
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        calls = read_log(self.jj_log)
        commit_call = ["commit", "--interactive", "--message", "selected"]
        self.assertLess(
            calls.index(commit_call),
            next(index for index, call in enumerate(calls)
                 if "diff.files" in " ".join(call)),
        )

    def test_commit_message_failure_undoes_commit_and_reapplies_fixes(self):
        (self.root / ".pre-commit-config.yaml").write_text("repos: []\n")
        self.install_fixing_checker("commit-msg")
        result = self.run_wrapper(
            "commit", "--message", "test: invalid later",
            env={
                "PATH": self.install_git_diff_mock("plain"),
                "FAKE_COMMIT_ID_AFTER_HOOK": "3" * 40,
                "FAKE_AFTER_HOOK_STAGE": "commit-msg",
            },
        )
        self.assertEqual(result.returncode, 9)
        calls = read_log(self.jj_log)
        self.assertIn(
            ["commit", "--message", "test: invalid later"], calls
        )
        self.assertIn(["op", "restore", "operation-before-split"], calls)
        self.assertIn(
            ["restore", "--from", "3" * 40, "--", "plain"], calls
        )
        stages = [
            call[call.index("--hook-stage") + 1]
            for call in read_log(self.checker_log)
        ]
        self.assertEqual(
            stages, ["pre-commit", "prepare-commit-msg", "commit-msg"]
        )

    def test_prepare_message_failure_undoes_commit_and_reapplies_fixes(self):
        (self.root / ".pre-commit-config.yaml").write_text("repos: []\n")
        self.install_fixing_checker("prepare-commit-msg")
        result = self.run_wrapper(
            "commit", "--message", "test: invalid preparation",
            env={
                "PATH": self.install_git_diff_mock("plain"),
                "FAKE_COMMIT_ID_AFTER_HOOK": "3" * 40,
                "FAKE_AFTER_HOOK_STAGE": "prepare-commit-msg",
            },
        )
        self.assertEqual(result.returncode, 9)
        calls = read_log(self.jj_log)
        self.assertIn(["op", "restore", "operation-before-split"], calls)
        self.assertIn(
            ["restore", "--from", "3" * 40, "--", "plain"], calls
        )
        stages = [
            call[call.index("--hook-stage") + 1]
            for call in read_log(self.checker_log)
        ]
        self.assertEqual(stages, ["pre-commit", "prepare-commit-msg"])

    def test_missing_configuration_skips_hooks(self):
        result = self.run_wrapper("commit", "--message", "test: no config")
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertEqual(read_log(self.checker_log), [])
        self.assertIn(
            ["commit", "--message", "test: no config"],
            read_log(self.jj_log),
        )

    def test_describe_forwards_arguments_then_checks_final_message(self):
        (self.root / ".pre-commit-config.yaml").write_text("repos: []\n")
        result = self.run_wrapper(
            "describe", "-r", "feature", "--message", "test: described"
        )
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        calls = read_log(self.jj_log)
        self.assertIn(
            ["describe", "-r", "feature", "--message", "test: described"],
            calls,
        )
        checker_calls = read_log(self.checker_log)
        self.assertEqual(len(checker_calls), 2)
        self.assertIn("prepare-commit-msg", checker_calls[0])
        self.assertIn("commit-msg", checker_calls[1])
        message_path = checker_calls[1][
            checker_calls[1].index("--commit-msg-filename") + 1
        ]
        self.assertFalse(Path(message_path).exists())

    def test_describe_failure_undoes_description_and_reapplies_fixes(self):
        (self.root / ".pre-commit-config.yaml").write_text("repos: []\n")
        self.install_fixing_checker("commit-msg")
        result = self.run_wrapper(
            "describe", "--message", "invalid",
            env={
                "PATH": self.install_git_diff_mock("plain"),
                "FAKE_COMMIT_ID_AFTER_HOOK": "3" * 40,
                "FAKE_AFTER_HOOK_STAGE": "commit-msg",
            },
        )
        self.assertEqual(result.returncode, 9)
        calls = read_log(self.jj_log)
        self.assertIn(["describe", "--message", "invalid"], calls)
        self.assertIn(["op", "restore", "operation-before-split"], calls)
        self.assertIn(
            ["restore", "--from", "3" * 40, "--", "plain"], calls
        )

    def test_split_checks_selected_change_after_successful_split(self):
        (self.root / ".pre-commit-config.yaml").write_text("repos: []\n")
        result = self.run_wrapper(
            "split", "-r", "feature", "src", "tests"
        )
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        calls = read_log(self.jj_log)
        split_call = ["split", "-r", "feature", "src", "tests"]
        self.assertIn(split_call, calls)
        self.assertLess(
            calls.index(split_call),
            next(index for index, call in enumerate(calls)
                 if "diff.files" in " ".join(call)),
        )
        checker_calls = read_log(self.checker_log)
        self.assertEqual(len(checker_calls), 1)
        self.assertIn("pre-commit", checker_calls[0])
        self.assertEqual(
            checker_calls[0][checker_calls[0].index("--files") + 1:],
            ["plain", "space name", "line\nbreak"],
        )

    def test_split_onto_checks_new_selected_change(self):
        (self.root / ".pre-commit-config.yaml").write_text("repos: []\n")
        result = self.run_wrapper(
            "split", "--onto=main", "src",
            env={
                "FAKE_ALL_CHANGE_IDS": json.dumps(["original", "main"]),
                "FAKE_ALL_CHANGE_IDS_AFTER": json.dumps(
                    ["original", "main", "selected"]
                ),
            },
        )
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        file_queries = [
            call for call in read_log(self.jj_log)
            if "diff.files" in " ".join(call)
        ]
        self.assertEqual(file_queries[-1][file_queries[-1].index("-r") + 1],
                         "selected")

    def test_split_failure_does_not_run_hooks(self):
        (self.root / ".pre-commit-config.yaml").write_text("repos: []\n")
        result = self.run_wrapper(
            "split", "src", env={"FAKE_SPLIT_EXIT": "17"}
        )
        self.assertEqual(result.returncode, 17)
        self.assertEqual(read_log(self.checker_log), [])

    def test_split_hook_failure_restores_original_operation(self):
        (self.root / ".pre-commit-config.yaml").write_text("repos: []\n")
        result = self.run_wrapper(
            "split", "src", env={"FAKE_CHECKER_EXIT": "9"}
        )
        self.assertEqual(result.returncode, 9)
        calls = read_log(self.jj_log)
        self.assertIn(["split", "src"], calls)
        self.assertIn(
            ["op", "restore", "operation-before-split"], calls
        )
        self.assertLess(
            calls.index(["split", "src"]),
            calls.index(["op", "restore", "operation-before-split"]),
        )

    def test_split_hook_fixes_are_reapplied_after_rollback(self):
        (self.root / ".pre-commit-config.yaml").write_text("repos: []\n")
        self.install_fixing_checker("pre-commit")
        result = self.run_wrapper(
            "split", "plain",
            env={
                "PATH": self.install_git_diff_mock("plain"),
                "FAKE_COMMIT_ID_AFTER_HOOK": "3" * 40,
            },
        )
        self.assertEqual(result.returncode, 9)
        calls = read_log(self.jj_log)
        self.assertIn(
            ["op", "restore", "operation-before-split"], calls
        )
        self.assertIn(
            ["restore", "--from", "3" * 40, "--", "plain"], calls
        )
        self.assertEqual(
            (self.root / "plain").read_text(), "fixed by hook\n"
        )

    def test_installed_pre_commit_hook_sees_jj_change_as_staged(self):
        self.prepare_git_range()
        self.env["FAKE_PARENT_ID"] = self.old_commit
        self.env["FAKE_COMMIT_ID"] = self.new_commit
        hook_log = self.base / "staged.log"
        hook = self.root / ".git" / "hooks" / "pre-commit"
        executable(
            hook,
            "#!/bin/sh\ngit diff --cached --name-only -z > \"$HOOK_LOG\"\n",
        )
        result = self.run_wrapper(
            "commit", "--message", "test: installed hook",
            env={
                "HOOK_LOG": str(hook_log),
                "FAKE_FILES": json.dumps(["changed file"]),
            },
        )
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertEqual(
            [value for value in hook_log.read_bytes().split(b"\0") if value],
            [b"changed file"],
        )

    def test_pre_commit_managed_git_hook_uses_checker_fallback(self):
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        (self.root / ".pre-commit-config.yaml").write_text("repos: []\n")
        hook = self.root / ".git" / "hooks" / "pre-commit"
        executable(
            hook,
            "#!/bin/sh\n# File generated by pre-commit: test\nexit 88\n",
        )
        result = self.run_wrapper("commit", "--message", "test: fallback")
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        checker_calls = read_log(self.checker_log)
        self.assertEqual(len(checker_calls), 3)
        self.assertIn("pre-commit", checker_calls[0])
        self.assertIn("prepare-commit-msg", checker_calls[1])
        self.assertIn("commit-msg", checker_calls[2])

    def test_pre_commit_managed_commit_msg_hook_uses_checker_fallback(self):
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        (self.root / ".pre-commit-config.yaml").write_text("repos: []\n")
        hook = self.root / ".git" / "hooks" / "commit-msg"
        executable(
            hook,
            "#!/bin/sh\n# File generated by pre-commit: test\nexit 88\n",
        )
        result = self.run_wrapper("describe", "--message", "test: fallback")
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        checker_calls = read_log(self.checker_log)
        self.assertEqual(len(checker_calls), 2)
        self.assertIn("prepare-commit-msg", checker_calls[0])
        self.assertIn("commit-msg", checker_calls[1])

    def test_pre_commit_managed_prepare_message_hook_uses_checker_fallback(self):
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        (self.root / ".pre-commit-config.yaml").write_text("repos: []\n")
        hook = self.root / ".git" / "hooks" / "prepare-commit-msg"
        executable(
            hook,
            "#!/bin/sh\n# File generated by pre-commit: test\nexit 88\n",
        )
        result = self.run_wrapper("describe", "--message", "test: fallback")
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        checker_calls = read_log(self.checker_log)
        self.assertEqual(len(checker_calls), 2)
        self.assertIn("prepare-commit-msg", checker_calls[0])
        self.assertIn("commit-msg", checker_calls[1])

    def test_pre_commit_managed_pre_push_hook_uses_checker_fallback(self):
        self.prepare_git_range()
        (self.root / ".pre-commit-config.yaml").write_text("repos: []\n")
        hook = self.root / ".git" / "hooks" / "pre-push"
        executable(
            hook,
            "#!/bin/sh\n# File generated by pre-commit: test\nexit 88\n",
        )
        plan = (
            "Changes to push to origin:\n"
            "  bookmark: main [move forward from {0} to {1}]\n"
            "Dry-run requested, not pushing.\n"
        ).format(self.old_commit, self.new_commit)
        result = self.run_wrapper(
            "git", "push", "--bookmark", "main",
            env={"FAKE_PUSH_PLAN": plan},
        )
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        checker_calls = read_log(self.checker_log)
        self.assertEqual(len(checker_calls), 1)
        self.assertIn("pre-push", checker_calls[0])
        self.assertIn(
            ["git", "push", "--bookmark", "main"], read_log(self.jj_log)
        )

    def test_prepare_message_hook_edits_description_before_commit_msg(self):
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        prepare_log = self.base / "prepare.log"
        hook = self.root / ".git" / "hooks" / "prepare-commit-msg"
        executable(
            hook,
            "#!/bin/sh\n"
            "printf '%s' \"$2\" > \"$PREPARE_LOG\"\n"
            "printf 'test: prepared\\n' > \"$1\"\n",
        )
        result = self.run_wrapper(
            "describe", "--message", "test: original",
            env={"PREPARE_LOG": str(prepare_log)},
        )
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertEqual(prepare_log.read_text(), "message")
        self.assertIn(
            ["describe", "--ignore-working-copy", "-r",
             self.env["FAKE_CHANGE_ID"], "--message", "test: prepared\n"],
            read_log(self.jj_log),
        )

    def test_installed_git_hook_takes_precedence_over_configuration(self):
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        hook_log = self.base / "hook.log"
        hook = self.root / ".git" / "hooks" / "commit-msg"
        executable(hook, "#!/bin/sh\nprintf '%s' \"$(cat \"$1\")\" > \"$HOOK_LOG\"\n")
        result = self.run_wrapper(
            "describe", "--message", "test: hook",
            env={"HOOK_LOG": str(hook_log)},
        )
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertEqual(
            hook_log.read_text(), "test: finalized description"
        )
        self.assertEqual(read_log(self.checker_log), [])

    def test_push_without_hook_configuration_passes_through(self):
        result = self.run_wrapper("git", "push", "--bookmark", "main")
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        calls = read_log(self.jj_log)
        self.assertIn(["git", "push", "--bookmark", "main"], calls)
        self.assertFalse(any("--dry-run" in call for call in calls))

    def test_installed_pre_push_hook_receives_git_protocol(self):
        self.prepare_git_range()
        hook_log = self.base / "pre-push.log"
        hook = self.root / ".git" / "hooks" / "pre-push"
        executable(
            hook,
            "#!/bin/sh\nprintf '%s\\n%s\\n' \"$1\" \"$2\" > \"$HOOK_LOG\"\n"
            "cat >> \"$HOOK_LOG\"\n",
        )
        plan = (
            "Changes to push to origin:\n"
            "  bookmark: main [move forward from {0} to {1}]\n"
            "Dry-run requested, not pushing.\n"
        ).format(self.old_commit, self.new_commit)
        result = self.run_wrapper(
            "git", "push", "--bookmark", "main",
            env={"FAKE_PUSH_PLAN": plan, "HOOK_LOG": str(hook_log)},
        )
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        lines = hook_log.read_text().splitlines()
        self.assertEqual(lines[0], "origin")
        self.assertEqual(lines[2], (
            "refs/heads/main {0} refs/heads/main {1}"
        ).format(self.new_commit, self.old_commit))
        self.assertEqual(read_log(self.checker_log), [])

    def test_push_checks_plan_before_forwarding_original_arguments(self):
        self.prepare_git_range()
        (self.root / ".pre-commit-config.yaml").write_text("repos: []\n")
        plan = (
            "Changes to push to origin:\n"
            "  bookmark: main [move forward from {0} to {1}]\n"
            "Dry-run requested, not pushing.\n"
        ).format(self.old_commit, self.new_commit)
        result = self.run_wrapper(
            "git", "push", "--remote", "origin", "--bookmark", "main",
            env={"FAKE_PUSH_PLAN": plan},
        )
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        checker_calls = read_log(self.checker_log)
        self.assertEqual(len(checker_calls), 1)
        self.assertIn("pre-push", checker_calls[0])
        self.assertIn("changed file", checker_calls[0])
        self.assertIn(
            ["git", "push", "--remote", "origin", "--bookmark", "main"],
            read_log(self.jj_log),
        )

    def test_push_hook_failure_prevents_real_push(self):
        self.prepare_git_range()
        (self.root / ".pre-commit-config.yaml").write_text("repos: []\n")
        plan = (
            "Changes to push to origin:\n"
            "  bookmark: main [move forward from {0} to {1}]\n"
            "Dry-run requested, not pushing.\n"
        ).format(self.old_commit, self.new_commit)
        result = self.run_wrapper(
            "git", "push", "--bookmark", "main",
            env={"FAKE_PUSH_PLAN": plan, "FAKE_CHECKER_EXIT": "7"},
        )
        self.assertEqual(result.returncode, 7)
        self.assertNotIn(
            ["git", "push", "--bookmark", "main"],
            read_log(self.jj_log),
        )

    def test_push_failure_restores_workspace_and_reapplies_fixes(self):
        (self.root / ".pre-commit-config.yaml").write_text("repos: []\n")
        self.install_fixing_checker("pre-push")
        plan = (
            "Changes to push to origin:\n"
            "  bookmark: main [move forward from {0} to {1}]\n"
            "Dry-run requested, not pushing.\n"
        ).format("1" * 40, "2" * 40)
        result = self.run_wrapper(
            "git", "push", "--bookmark", "main",
            env={
                "PATH": self.install_git_diff_mock("plain"),
                "FAKE_PUSH_PLAN": plan,
                "FAKE_COMMIT_ID_AFTER_HOOK": "3" * 40,
                "FAKE_AFTER_HOOK_STAGE": "pre-push",
            },
        )
        self.assertEqual(result.returncode, 9)
        calls = read_log(self.jj_log)
        self.assertNotIn(
            ["git", "push", "--bookmark", "main"], calls
        )
        self.assertIn(["op", "restore", "operation-before-split"], calls)
        self.assertIn(
            ["restore", "--from", "3" * 40, "--", "plain"], calls
        )

    def prepare_git_range(self):
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        subprocess.run(
            ["git", "-C", str(self.root), "config", "user.name", "Test"],
            check=True,
        )
        subprocess.run(
            ["git", "-C", str(self.root), "config", "user.email", "test@example.com"],
            check=True,
        )
        changed = self.root / "changed file"
        changed.write_text("old\n")
        subprocess.run(
            ["git", "-C", str(self.root), "add", "changed file"], check=True
        )
        subprocess.run(
            ["git", "-C", str(self.root), "commit", "-qm", "old"], check=True
        )
        self.old_commit = subprocess.check_output(
            ["git", "-C", str(self.root), "rev-parse", "HEAD"]
        ).decode().strip()
        changed.write_text("new\n")
        subprocess.run(
            ["git", "-C", str(self.root), "commit", "-qam", "new"], check=True
        )
        self.new_commit = subprocess.check_output(
            ["git", "-C", str(self.root), "rev-parse", "HEAD"]
        ).decode().strip()
        self.env["FAKE_GIT_DIR"] = str(self.root / ".git")


if __name__ == "__main__":
    unittest.main()
