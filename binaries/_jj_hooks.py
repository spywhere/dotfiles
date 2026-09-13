#!/usr/bin/env python3

"""Run selected Jujutsu commands through repository validation hooks."""

import os
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import uuid
from contextlib import contextmanager


ACTIVE_ENV = "JJ_HOOKS_ACTIVE"
REAL_JJ_ENV = "JJ_HOOKS_REAL_JJ"
ZERO_COMMIT = "0" * 40
NO_FILES_SENTINEL = ".jj-hooks-no-files"

GLOBAL_VALUE_OPTIONS = {
    "-R",
    "--repository",
    "--at-operation",
    "--at-op",
    "--color",
    "--config",
    "--config-file",
}
GLOBAL_FLAG_OPTIONS = {
    "--ignore-working-copy",
    "--no-integrate-operation",
    "--ignore-immutable",
    "--debug",
    "--quiet",
    "--no-pager",
}

UPDATE_PATTERNS = (
    ("move", re.compile(
        r"Move (?:forward|backward|sideways) bookmark (?P<bookmark>\S+) "
        r"from (?P<old>\w+) to (?P<new>\w+)"
    )),
    ("move", re.compile(
        r"^\s*bookmark:\s+(?P<bookmark>\S+)\s+\[move "
        r"(?:forward|backward|sideways) from (?P<old>\w+) to (?P<new>\w+)\]"
    )),
    ("add", re.compile(
        r"Add bookmark (?P<bookmark>\S+) to (?P<new>\w+)"
    )),
    ("add", re.compile(
        r"^\s*bookmark:\s+(?P<bookmark>\S+)\s+\[add to (?P<new>\w+)\]"
    )),
    ("delete", re.compile(
        r"Delete bookmark (?P<bookmark>\S+) from (?P<old>\w+)"
    )),
    ("delete", re.compile(
        r"^\s*bookmark:\s+(?P<bookmark>\S+)\s+\[delete from (?P<old>\w+)\]"
    )),
)
REMOTE_PATTERN = re.compile(r"^Changes to push to (.+?):")


def error(message):
    sys.stderr.write("jj hooks: {0}\n".format(message))


def canonical(path):
    return os.path.realpath(os.path.abspath(path))


def resolve_real_jj():
    configured = os.environ.get(REAL_JJ_ENV)
    wrapper = canonical(sys.argv[0])
    if configured and os.access(configured, os.X_OK):
        if canonical(configured) != wrapper:
            return canonical(configured)

    for directory in os.environ.get("PATH", "").split(os.pathsep):
        if not directory:
            directory = os.curdir
        candidate = os.path.join(directory, "jj")
        if not os.path.isfile(candidate) or not os.access(candidate, os.X_OK):
            continue
        if canonical(candidate) != wrapper:
            return canonical(candidate)

    error("cannot find the real jj executable after the wrapper in PATH")
    return None


def child_env(real_jj, extra=None):
    env = os.environ.copy()
    env[ACTIVE_ENV] = "1"
    env[REAL_JJ_ENV] = real_jj
    if extra:
        env.update(extra)
    return env


def relay_signal(returncode):
    if returncode >= 0:
        return returncode
    signum = -returncode
    signal.signal(signum, signal.SIG_DFL)
    os.kill(os.getpid(), signum)
    return 128 + signum


def run_process(argv, real_jj, cwd=None, env_extra=None, input_data=None,
                capture=False):
    stdout = subprocess.PIPE if capture else None
    stderr = subprocess.STDOUT if capture else None
    process = subprocess.Popen(
        argv,
        cwd=cwd,
        env=child_env(real_jj, env_extra),
        stdin=subprocess.PIPE if input_data is not None else None,
        stdout=stdout,
        stderr=stderr,
    )
    output = None
    try:
        output, unused_stderr = process.communicate(input_data)
    except KeyboardInterrupt:
        # The terminal sends the same signal to the foreground child. Wait for
        # its real status instead of replacing it with a Python traceback.
        while True:
            try:
                returncode = process.wait()
                break
            except KeyboardInterrupt:
                continue
        return returncode, output
    return process.returncode, output


def run_jj(real_jj, args, cwd=None, capture=False):
    return run_process([real_jj] + list(args), real_jj, cwd=cwd,
                       capture=capture)


def exec_real(real_jj, args):
    os.environ[ACTIVE_ENV] = "1"
    os.environ[REAL_JJ_ENV] = real_jj
    os.execv(real_jj, [real_jj] + list(args))


def option_takes_value(arg):
    return arg in GLOBAL_VALUE_OPTIONS


def split_command(args):
    index = 0
    while index < len(args):
        arg = args[index]
        if arg == "--":
            if index + 1 < len(args):
                return index + 1, args[index + 1]
            return None, None
        if option_takes_value(arg):
            index += 2
            continue
        if any(arg.startswith(option + "=") for option in GLOBAL_VALUE_OPTIONS
               if option.startswith("--")):
            index += 1
            continue
        if arg.startswith("-R") and arg != "-R":
            index += 1
            continue
        if arg.startswith("-"):
            index += 1
            continue
        return index, arg
    return None, None


def global_args(args, command_index):
    result = []
    index = 0
    while index < len(args):
        if index == command_index:
            index += 1
            continue
        arg = args[index]
        if option_takes_value(arg):
            result.append(arg)
            if index + 1 < len(args):
                result.append(args[index + 1])
            index += 2
            continue
        if any(arg.startswith(option + "=") for option in GLOBAL_VALUE_OPTIONS
               if option.startswith("--")):
            result.append(arg)
        elif arg.startswith("-R") and arg != "-R":
            result.append(arg)
        elif arg in GLOBAL_FLAG_OPTIONS:
            result.append(arg)
        index += 1
    return result


def jj_output(real_jj, globals_, args, cwd=None):
    returncode, output = run_jj(
        real_jj,
        list(globals_) + list(args) + ["--color=never", "--no-pager"],
        cwd=cwd,
        capture=True,
    )
    if returncode != 0:
        return None
    return output


def workspace_root(real_jj, globals_):
    output = jj_output(
        real_jj, globals_, ["workspace", "root", "--ignore-working-copy"]
    )
    if output is None:
        return None
    return os.fsdecode(output).strip()


def git_store(real_jj, globals_, root):
    output = jj_output(
        real_jj, globals_, ["git", "root", "--ignore-working-copy"], cwd=root
    )
    if output is None:
        return None
    return os.fsdecode(output).strip()


def template_values(real_jj, globals_, root, revision, expression):
    output = jj_output(
        real_jj,
        globals_,
        ["log", "--ignore-working-copy", "--no-graph", "-r", revision,
         "-T", expression],
        cwd=root,
    )
    if output is None:
        return None
    return [value for value in output.split(b"\0") if value]


def change_ids(real_jj, globals_, root, revision):
    values = template_values(
        real_jj, globals_, root, revision, 'change_id ++ "\\0"'
    )
    if values is None:
        return None
    return [os.fsdecode(value) for value in values]


def current_operation(real_jj, globals_, root):
    output = jj_output(
        real_jj,
        globals_,
        ["op", "log", "-n", "1", "--no-graph", "-T",
         'self.id() ++ "\\0"'],
        cwd=root,
    )
    if output is None:
        return None
    values = [value for value in output.split(b"\0") if value]
    if not values:
        return None
    return os.fsdecode(values[0])


def commit_ids(real_jj, globals_, root, revision):
    values = template_values(
        real_jj, globals_, root, revision, 'commit_id ++ "\\0"'
    )
    if values is None:
        return None
    return [os.fsdecode(value) for value in values]


def changed_files(real_jj, globals_, root, revision, filesets=None):
    # JJ's templated diff output provides an unambiguous separator, including
    # for paths containing newlines. Use the diff command when filesets need to
    # be resolved with JJ's own fileset parser.
    if filesets is not None:
        returncode, output = run_jj(
            real_jj,
            list(globals_)
            + ["diff", "--ignore-working-copy", "-r", revision,
               "-T", 'path ++ "\\0"', "--color=never", "--no-pager",
               "--"]
            + list(filesets),
            cwd=root,
            capture=True,
        )
        if returncode != 0:
            return None
        return [path for path in (output or b"").split(b"\0") if path]
    return template_values(
        real_jj,
        globals_,
        root,
        revision,
        'diff.files().map(|file| file.path() ++ "\\0")',
    )


def revision_description(real_jj, globals_, root, revision):
    output = jj_output(
        real_jj,
        globals_,
        ["log", "--ignore-working-copy", "--no-graph", "-r", revision,
         "-T", "description"],
        cwd=root,
    )
    return output


def checker_config(root):
    path = os.path.join(root, ".pre-commit-config.yaml")
    if os.path.isfile(path):
        return path
    return None


def checker_executable():
    executable = shutil.which("pre-commit")
    if executable:
        return executable
    return shutil.which("prek")


def colocated_git(root):
    marker = os.path.join(root, ".git")
    if not os.path.exists(marker):
        return False
    try:
        output = subprocess.check_output(
            ["git", "-C", root, "rev-parse", "--show-toplevel"],
            stderr=subprocess.DEVNULL,
        )
    except (OSError, subprocess.CalledProcessError):
        return False
    return canonical(os.fsdecode(output).strip()) == canonical(root)


def installed_hook(root, hook_type):
    if not colocated_git(root):
        return None
    try:
        output = subprocess.check_output(
            ["git", "-C", root, "rev-parse", "--path-format=absolute",
             "--git-path", "hooks/{0}".format(hook_type)],
            stderr=subprocess.DEVNULL,
        )
    except (OSError, subprocess.CalledProcessError):
        return None
    path = os.fsdecode(output).strip()
    if os.path.isfile(path) and os.access(path, os.X_OK):
        return path
    return None


def pre_commit_managed_hook(path):
    if not path:
        return False
    try:
        with open(path, "rb") as hook_file:
            header = hook_file.read(4096)
    except OSError:
        return False
    return b"File generated by pre-commit" in header


def git_environment(real_jj, globals_, root):
    store = git_store(real_jj, globals_, root)
    if not store:
        return None
    return {
        "GIT_DIR": store,
        "GIT_WORK_TREE": root,
    }


@contextmanager
def temporary_git_view(real_jj, globals_, root, head_commit):
    git_env = git_environment(real_jj, globals_, root)
    if git_env is None:
        yield None
        return
    try:
        output = subprocess.check_output(
            ["git", "rev-parse", "--path-format=absolute",
             "--git-common-dir"],
            cwd=root,
            env=dict(os.environ, **git_env),
            stderr=subprocess.DEVNULL,
        )
    except (OSError, subprocess.CalledProcessError):
        yield None
        return
    common_dir = os.fsdecode(output).strip()
    with tempfile.TemporaryDirectory(prefix="jj-hooks-git-") as temp_git:
        with open(os.path.join(temp_git, "commondir"), "w") as handle:
            handle.write(common_dir + "\n")
        with open(os.path.join(temp_git, "HEAD"), "w") as handle:
            handle.write(head_commit + "\n")
        view_env = {
            "GIT_DIR": temp_git,
            "GIT_COMMON_DIR": common_dir,
            "GIT_WORK_TREE": root,
            "GIT_INDEX_FILE": os.path.join(temp_git, "index"),
        }
        returncode, unused_output = run_process(
            ["git", "read-tree", head_commit],
            real_jj,
            cwd=root,
            env_extra=view_env,
        )
        if returncode != 0:
            yield None
            return
        yield view_env


def snapshot_working_copy(real_jj, globals_, root):
    returncode, unused_output = run_jj(
        real_jj,
        list(globals_) + ["log", "--no-graph", "-r", "@", "-T", "",
                          "--color=never", "--no-pager"],
        cwd=root,
        capture=True,
    )
    return returncode


@contextmanager
def message_git_marker(root, git_env, message_path):
    """Expose a temporary .git marker for filesystem-based root discovery.

    Git subprocesses retain the existing GIT_DIR/GIT_WORK_TREE environment.
    The marker has its own COMMIT_EDITMSG for tools which ignore that
    environment and default to reading .git/COMMIT_EDITMSG instead.
    """
    marker = os.path.join(root, ".git")
    if os.path.lexists(marker):
        yield None
        return
    with tempfile.TemporaryDirectory(prefix="jj-hooks-message-git-") as view:
        with open(os.path.join(view, "commondir"), "w") as handle:
            handle.write(canonical(git_env["GIT_DIR"]) + "\n")
        with open(os.path.join(view, "HEAD"), "w") as handle:
            handle.write("ref: refs/heads/jj-hooks-message\n")
        default_message = os.path.join(view, "COMMIT_EDITMSG")
        shutil.copyfile(message_path, default_message)
        # Exclusive creation avoids replacing a concurrently-created .git.
        owned = None
        try:
            with open(marker, "x") as handle:
                owned = os.fstat(handle.fileno())
                handle.write("gitdir: {0}\n".format(view))
            yield default_message
        finally:
            if owned is not None:
                try:
                    current = os.lstat(marker)
                    if (current.st_dev, current.st_ino) == (
                            owned.st_dev, owned.st_ino):
                        os.unlink(marker)
                except FileNotFoundError:
                    pass


def run_checker(real_jj, globals_, root, hook_type, extra_args,
                checker_env=None):
    config = checker_config(root)
    if not config:
        return 0
    checker = checker_executable()
    if not checker:
        error("{0} exists, but neither pre-commit nor prek is installed".format(
            config
        ))
        return 1
    git_env = git_environment(real_jj, globals_, root)
    if git_env is None:
        error("cannot expose this JJ repository to {0}".format(
            os.path.basename(checker)
        ))
        return 1
    if checker_env:
        git_env.update(checker_env)
    command = [checker, "run", "--hook-stage", hook_type]
    if os.path.basename(checker) == "pre-commit":
        command.extend(["--config", config])
    command.extend(extra_args)
    if hook_type in ("prepare-commit-msg", "commit-msg"):
        message_path = extra_args[extra_args.index("--commit-msg-filename") + 1]
        try:
            with open(message_path, "rb") as handle:
                original = handle.read()
            with message_git_marker(root, git_env, message_path) as default_message:
                returncode, unused_output = run_process(
                    command, real_jj, cwd=root, env_extra=git_env
                )
                if default_message:
                    with open(default_message, "rb") as handle:
                        prepared = handle.read()
                    if prepared != original:
                        with open(message_path, "rb") as handle:
                            explicit = handle.read()
                        if explicit not in (original, prepared):
                            error("hooks made conflicting edits to the message files")
                            return returncode or 1
                        with open(message_path, "wb") as handle:
                            handle.write(prepared)
                return returncode
        except OSError as exc:
            error("could not provide Git message context: {0}".format(exc))
            return 1
    returncode, unused_output = run_process(
        command, real_jj, cwd=root, env_extra=git_env
    )
    return returncode


def prepare_selected_index(real_jj, root, hook_env, parent, commit, files):
    if parent == ZERO_COMMIT:
        read_args = ["git", "read-tree", "--empty"]
    else:
        read_args = ["git", "read-tree", parent]
    returncode, unused_output = run_process(
        read_args, real_jj, cwd=root, env_extra=hook_env
    )
    if returncode != 0:
        return returncode

    for path in files:
        try:
            output = subprocess.check_output(
                ["git", "ls-tree", "-z", commit, "--", os.fsdecode(path)],
                cwd=root,
                env=dict(os.environ, **hook_env),
                stderr=subprocess.DEVNULL,
            )
        except (OSError, subprocess.CalledProcessError):
            return 1
        entries = [entry for entry in output.split(b"\0") if entry]
        if entries:
            metadata, unused_name = entries[0].split(b"\t", 1)
            mode, unused_type, object_id = metadata.split(b" ", 2)
            update_args = [
                "git", "update-index", "--add", "--cacheinfo",
                os.fsdecode(mode), os.fsdecode(object_id), os.fsdecode(path),
            ]
        else:
            update_args = [
                "git", "update-index", "--force-remove", "--",
                os.fsdecode(path),
            ]
        returncode, unused_output = run_process(
            update_args, real_jj, cwd=root, env_extra=hook_env
        )
        if returncode != 0:
            return returncode
    return 0


def run_pre_commit_stage(real_jj, globals_, root, revision, files=None):
    if files is None:
        files = changed_files(real_jj, globals_, root, revision)
    if files is None:
        error("could not determine files changed in {0}".format(revision))
        return 1

    hook = installed_hook(root, "pre-commit")
    use_checker = (
        pre_commit_managed_hook(hook)
        and checker_config(root)
        and checker_executable()
    )
    if hook and not use_checker:
        # Git hooks have no filename argument. Give the hook a temporary index
        # containing the JJ tree, with HEAD set to the first JJ parent. This is
        # the closest Git equivalent to the current JJ change and does not
        # modify the user's real index.
        commits = commit_ids(real_jj, globals_, root, revision)
        parents = commit_ids(real_jj, globals_, root, "parents({0})".format(
            revision
        ))
        if not commits or not parents:
            error("could not prepare the Git view for the pre-commit hook")
            return 1
        try:
            common_dir = subprocess.check_output(
                ["git", "-C", root, "rev-parse", "--path-format=absolute",
                 "--git-common-dir"],
                stderr=subprocess.DEVNULL,
            ).decode().strip()
        except (OSError, subprocess.CalledProcessError):
            error("could not prepare the Git view for the pre-commit hook")
            return 1
        with tempfile.TemporaryDirectory(prefix="jj-hooks-git-") as temp_git:
            with open(os.path.join(temp_git, "commondir"), "w") as handle:
                handle.write(common_dir + "\n")
            with open(os.path.join(temp_git, "HEAD"), "w") as handle:
                if parents[0] == ZERO_COMMIT:
                    handle.write("ref: refs/heads/jj-hooks-unborn\n")
                else:
                    handle.write(parents[0] + "\n")
            index = os.path.join(temp_git, "index")
            hook_env = {
                "GIT_DIR": temp_git,
                "GIT_COMMON_DIR": common_dir,
                "GIT_WORK_TREE": root,
                "GIT_INDEX_FILE": index,
            }
            returncode = prepare_selected_index(
                real_jj, root, hook_env, parents[0], commits[0], files
            )
            if returncode != 0:
                return returncode
            returncode, unused_output = run_process(
                [hook], real_jj, cwd=root, env_extra=hook_env
            )
            return returncode

    if not checker_config(root):
        return 0
    file_args = [os.fsdecode(path) for path in files]
    if not file_args:
        file_args = [NO_FILES_SENTINEL]
    return run_checker(
        real_jj, globals_, root, "pre-commit", ["--files"] + file_args
    )


def run_prepare_commit_message_stage(real_jj, globals_, root, revision,
                                     source=None):
    description = revision_description(real_jj, globals_, root, revision)
    if description is None:
        error("could not read the finalized description for {0}".format(
            revision
        ))
        return 1

    hook = installed_hook(root, "prepare-commit-msg")
    config = checker_config(root)
    use_checker = (
        pre_commit_managed_hook(hook)
        and config
        and checker_executable()
    )
    if not hook and not config:
        return 0

    message_path = None
    try:
        descriptor, message_path = tempfile.mkstemp(prefix="jj-description-")
        with os.fdopen(descriptor, "wb") as message_file:
            message_file.write(description)
            if description and not description.endswith(b"\n"):
                message_file.write(b"\n")
        if hook and not use_checker:
            env_extra = git_environment(real_jj, globals_, root) or {}
            command = [hook, message_path]
            if source:
                command.append(source)
            returncode, unused_output = run_process(
                command, real_jj, cwd=root, env_extra=env_extra
            )
        else:
            returncode = run_checker(
                real_jj,
                globals_,
                root,
                "prepare-commit-msg",
                ["--commit-msg-filename", message_path],
            )
        if returncode != 0:
            return returncode

        with open(message_path, "rb") as message_file:
            prepared = message_file.read()
        if prepared == description or prepared == description + b"\n":
            return 0
        returncode, unused_output = run_jj(
            real_jj,
            list(globals_)
            + ["describe", "--ignore-working-copy", "-r", revision,
               "--message", os.fsdecode(prepared)],
            cwd=root,
        )
        return returncode
    finally:
        if message_path:
            try:
                os.unlink(message_path)
            except FileNotFoundError:
                pass


def run_commit_message_stage(real_jj, globals_, root, revision):
    description = revision_description(real_jj, globals_, root, revision)
    if description is None:
        error("could not read the finalized description for {0}".format(
            revision
        ))
        return 1

    hook = installed_hook(root, "commit-msg")
    config = checker_config(root)
    use_checker = (
        pre_commit_managed_hook(hook)
        and config
        and checker_executable()
    )
    if not hook and not config:
        return 0

    message_path = None
    try:
        descriptor, message_path = tempfile.mkstemp(prefix="jj-description-")
        with os.fdopen(descriptor, "wb") as message_file:
            message_file.write(description)
            if description and not description.endswith(b"\n"):
                message_file.write(b"\n")
        if hook and not use_checker:
            env_extra = git_environment(real_jj, globals_, root) or {}
            returncode, unused_output = run_process(
                [hook, message_path], real_jj, cwd=root, env_extra=env_extra
            )
            return returncode
        return run_checker(
            real_jj,
            globals_,
            root,
            "commit-msg",
            ["--commit-msg-filename", message_path],
        )
    finally:
        if message_path:
            try:
                os.unlink(message_path)
            except FileNotFoundError:
                pass


def explicit_message(args, command_index):
    for arg in args[command_index + 1:]:
        if arg in ("-m", "--message"):
            return True
        if arg.startswith("--message=") or (
                arg.startswith("-m") and arg != "-m"):
            return True
    return False


def commit_selection(args, command_index):
    filesets = []
    interactive = False
    index = command_index + 1
    positional = False
    while index < len(args):
        arg = args[index]
        if positional:
            filesets.append(arg)
            index += 1
            continue
        if arg == "--":
            positional = True
            index += 1
            continue
        if arg in ("-i", "--interactive"):
            interactive = True
            index += 1
            continue
        if arg == "--tool":
            interactive = True
            index += 2
            continue
        if arg.startswith("--tool="):
            interactive = True
            index += 1
            continue
        if arg in ("-m", "--message") or option_takes_value(arg):
            index += 2
            continue
        if arg.startswith("--message=") or (
                arg.startswith("-m") and arg != "-m"):
            index += 1
            continue
        if any(arg.startswith(option + "=") for option in GLOBAL_VALUE_OPTIONS
               if option.startswith("--")):
            index += 1
            continue
        if arg.startswith("-R") and arg != "-R":
            index += 1
            continue
        if arg.startswith("-"):
            index += 1
            continue
        filesets.append(arg)
        index += 1
    return filesets, interactive


def split_details(args, command_index):
    revision = "@"
    extracts_selected = False
    extracting_options = (
        "-o", "--onto", "-d", "--destination",
        "-A", "--insert-after", "--after",
        "-B", "--insert-before", "--before",
    )
    index = command_index + 1
    while index < len(args):
        arg = args[index]
        if arg in ("-r", "--revision"):
            if index + 1 < len(args):
                revision = args[index + 1]
            index += 2
            continue
        if arg in extracting_options:
            extracts_selected = True
            index += 2
            continue
        if arg.startswith("--revision="):
            revision = arg.split("=", 1)[1]
        elif arg.startswith("-r") and arg != "-r":
            revision = arg[2:]
        elif any(arg.startswith(option + "=")
                 for option in extracting_options if option.startswith("--")):
            extracts_selected = True
        elif any(arg.startswith(option) and arg != option
                 for option in ("-o", "-d", "-A", "-B")):
            extracts_selected = True
        index += 1
    return revision, extracts_selected


def describe_revisions(args, command_index):
    revisions = []
    index = command_index + 1
    positional = False
    while index < len(args):
        arg = args[index]
        if positional:
            revisions.append(arg)
            index += 1
            continue
        if arg == "--":
            positional = True
            index += 1
            continue
        if arg in ("-m", "--message", "-r"):
            if index + 1 < len(args) and arg == "-r":
                revisions.append(args[index + 1])
            index += 2
            continue
        if arg.startswith("--message=") or (
                arg.startswith("-m") and arg != "-m"):
            index += 1
            continue
        if option_takes_value(arg):
            index += 2
            continue
        if any(arg.startswith(option + "=") for option in GLOBAL_VALUE_OPTIONS
               if option.startswith("--")):
            index += 1
            continue
        if arg.startswith("-R") and arg != "-R":
            index += 1
            continue
        if arg.startswith("-"):
            index += 1
            continue
        revisions.append(arg)
        index += 1
    return revisions or ["@"]


def handle_commit(real_jj, args, command_index, globals_, root):
    if snapshot_working_copy(real_jj, globals_, root) != 0:
        exec_real(real_jj, args)
    revisions = change_ids(real_jj, globals_, root, "@")
    if not revisions:
        exec_real(real_jj, args)
    revision = revisions[0]
    filesets, interactive = commit_selection(args, command_index)
    selected_files = None
    if filesets and not interactive:
        selected_files = changed_files(
            real_jj, globals_, root, revision, filesets=filesets
        )
        if selected_files is None:
            error("could not determine files selected by jj commit")
            return 1
    if not interactive:
        returncode = run_pre_commit_stage(
            real_jj, globals_, root, revision, files=selected_files
        )
        if returncode != 0:
            return returncode

    operation = current_operation(real_jj, globals_, root)
    if not operation:
        exec_real(real_jj, args)
    returncode, unused_output = run_jj(real_jj, args, cwd=None)
    if returncode != 0:
        return returncode
    working_commits = commit_ids(real_jj, globals_, root, "@")
    if not working_commits:
        error("could not snapshot the working copy before commit validation")
        return 1
    if interactive:
        returncode = run_pre_commit_stage(
            real_jj, globals_, root, revision
        )
        if returncode != 0:
            rollback_failed_hook(
                real_jj, globals_, root, operation, working_commits[0],
                "commit"
            )
            return returncode
    source = "message" if explicit_message(args, command_index) else None
    returncode = run_prepare_commit_message_stage(
        real_jj, globals_, root, revision, source=source
    )
    if returncode == 0:
        returncode = run_commit_message_stage(
            real_jj, globals_, root, revision
        )
    if returncode == 0:
        return 0
    rollback_failed_hook(
        real_jj, globals_, root, operation, working_commits[0], "commit"
    )
    return returncode


def snapshot_hook_changes(real_jj, globals_, root, before_commit):
    if snapshot_working_copy(real_jj, globals_, root) != 0:
        error("could not snapshot changes made by the failed hook")
        return None, None
    commits = commit_ids(real_jj, globals_, root, "@")
    if not commits:
        error("could not identify changes made by the failed hook")
        return None, None
    after_commit = commits[0]
    if after_commit == before_commit:
        return after_commit, []
    git_env = git_environment(real_jj, globals_, root)
    if git_env is None:
        error("could not preserve changes made by the failed hook")
        return after_commit, None
    paths = git_paths(
        root,
        git_env,
        ["diff", "--name-only", "-z", before_commit, after_commit],
    )
    if paths is None:
        error("could not identify files changed by the failed hook")
    return after_commit, paths


def restore_hook_changes(real_jj, root, commit, paths):
    if not commit or not paths:
        return 0
    returncode, unused_output = run_jj(
        real_jj,
        ["restore", "--from", commit, "--"]
        + [os.fsdecode(path) for path in paths],
        cwd=root,
    )
    return returncode


def rollback_failed_hook(real_jj, globals_, root, operation, before_hook,
                         command):
    hook_commit, hook_paths = snapshot_hook_changes(
        real_jj, globals_, root, before_hook
    )
    restore_code, unused_output = run_jj(
        real_jj, ["op", "restore", operation], cwd=root
    )
    if restore_code != 0:
        error(
            "{0} validation failed and the original operation could not be "
            "restored".format(command)
        )
        return False
    if hook_paths is None:
        if hook_commit:
            error("hook changes remain available in commit {0}".format(
                hook_commit
            ))
        return False

    apply_code = restore_hook_changes(
        real_jj, root, hook_commit, hook_paths
    )
    if apply_code != 0:
        error(
            "the {0} operation was undone, but hook changes could not be "
            "reapplied".format(command)
        )
        if hook_commit:
            error("hook changes remain available in commit {0}".format(
                hook_commit
            ))
        return False
    return True


def handle_split(real_jj, args, command_index, globals_, root):
    target, extracts_selected = split_details(args, command_index)
    revisions = change_ids(real_jj, globals_, root, target)
    if not revisions:
        exec_real(real_jj, args)
    revision = revisions[0]
    operation = current_operation(real_jj, globals_, root)
    if not operation:
        exec_real(real_jj, args)
    previous_changes = None
    if extracts_selected:
        previous_changes = set(change_ids(
            real_jj, globals_, root, "all()"
        ) or [])

    returncode, unused_output = run_jj(real_jj, args, cwd=None)
    if returncode != 0:
        return returncode
    if extracts_selected:
        current_changes = change_ids(real_jj, globals_, root, "all()")
        selected = [change for change in (current_changes or [])
                    if change not in previous_changes]
        if len(selected) != 1:
            error("could not identify the selected change after jj split")
            return 1
        revision = selected[0]

    working_commits = commit_ids(real_jj, globals_, root, "@")
    if not working_commits:
        error("could not snapshot the working copy before split validation")
        return 1
    before_hook = working_commits[0]
    returncode = run_pre_commit_stage(
        real_jj, globals_, root, revision
    )
    if returncode == 0:
        return 0

    rollback_failed_hook(
        real_jj, globals_, root, operation, before_hook, "split"
    )
    return returncode


def handle_describe(real_jj, args, command_index, globals_, root):
    operation = current_operation(real_jj, globals_, root)
    if not operation:
        exec_real(real_jj, args)
    revisions = []
    for revision in describe_revisions(args, command_index):
        resolved = change_ids(real_jj, globals_, root, revision)
        if resolved:
            for change_id in resolved:
                if change_id not in revisions:
                    revisions.append(change_id)

    returncode, unused_output = run_jj(real_jj, args, cwd=None)
    if returncode != 0:
        return returncode
    working_commits = commit_ids(real_jj, globals_, root, "@")
    if not working_commits:
        error("could not snapshot the working copy before commit-msg validation")
        return 1
    source = "message" if explicit_message(args, command_index) else None
    for revision in revisions:
        returncode = run_prepare_commit_message_stage(
            real_jj, globals_, root, revision, source=source
        )
        if returncode == 0:
            returncode = run_commit_message_stage(
                real_jj, globals_, root, revision
            )
        if returncode != 0:
            rollback_failed_hook(
                real_jj, globals_, root, operation, working_commits[0],
                "describe"
            )
            return returncode
    return 0


def parse_push_updates(output):
    updates = []
    remote = None
    for line in os.fsdecode(output).splitlines():
        remote_match = REMOTE_PATTERN.search(line)
        if remote_match:
            remote = remote_match.group(1)
            continue
        for update_type, pattern in UPDATE_PATTERNS:
            match = pattern.search(line)
            if not match:
                continue
            values = match.groupdict()
            updates.append({
                "type": update_type,
                "remote": remote,
                "bookmark": values.get("bookmark"),
                "old": values.get("old"),
                "new": values.get("new"),
            })
            break
    return updates


def remote_url(root, git_env, remote):
    try:
        output = subprocess.check_output(
            ["git", "config", "--get", "remote.{0}.url".format(remote)],
            cwd=root,
            env=dict(os.environ, **git_env),
            stderr=subprocess.DEVNULL,
        )
    except (OSError, subprocess.CalledProcessError):
        return remote
    return os.fsdecode(output).strip() or remote


def pre_push_input(update):
    local_commit = update.get("new") or ZERO_COMMIT
    remote_commit = update.get("old") or ZERO_COMMIT
    bookmark = update["bookmark"]
    line = "refs/heads/{0} {1} refs/heads/{0} {2}\n".format(
        bookmark, local_commit, remote_commit
    )
    return line.encode()


def git_paths(root, git_env, args):
    try:
        output = subprocess.check_output(
            ["git"] + list(args),
            cwd=root,
            env=dict(os.environ, **git_env),
            stderr=subprocess.DEVNULL,
        )
    except (OSError, subprocess.CalledProcessError):
        return None
    return [path for path in output.split(b"\0") if path]


def new_bookmark_base(root, git_env, remote, new_commit):
    try:
        output = subprocess.check_output(
            ["git", "rev-list", new_commit, "--topo-order", "--reverse",
             "--not", "--remotes={0}".format(remote)],
            cwd=root,
            env=dict(os.environ, **git_env),
            stderr=subprocess.DEVNULL,
        )
    except (OSError, subprocess.CalledProcessError):
        return None, False
    commits = os.fsdecode(output).splitlines()
    if not commits:
        return None, False
    first = commits[0]
    try:
        output = subprocess.check_output(
            ["git", "rev-parse", "{0}^".format(first)],
            cwd=root,
            env=dict(os.environ, **git_env),
            stderr=subprocess.DEVNULL,
        )
    except (OSError, subprocess.CalledProcessError):
        return None, True
    return os.fsdecode(output).strip(), False


def run_pre_push_stage(real_jj, globals_, root, update):
    hook = installed_hook(root, "pre-push")
    use_checker = (
        pre_commit_managed_hook(hook)
        and checker_config(root)
        and checker_executable()
    )
    git_env = git_environment(real_jj, globals_, root)
    if git_env is None:
        error("cannot expose this JJ repository to the pre-push hook")
        return 1
    remote = update.get("remote")
    if not remote:
        error("could not determine the push remote from jj --dry-run output")
        return 1

    if hook and not use_checker:
        url = remote_url(root, git_env, remote)
        head_commit = update.get("new") or update.get("old")
        with temporary_git_view(
                real_jj, globals_, root, head_commit) as view_env:
            if view_env is None:
                error("could not prepare the Git view for the pre-push hook")
                return 1
            returncode, unused_output = run_process(
                [hook, remote, url],
                real_jj,
                cwd=root,
                env_extra=view_env,
                input_data=pre_push_input(update),
            )
            return returncode

    if not checker_config(root) or update["type"] == "delete":
        return 0

    base = update.get("old")
    all_files = False
    if not base:
        base, all_files = new_bookmark_base(
            root, git_env, remote, update["new"]
        )
    if all_files:
        files = git_paths(
            root,
            git_env,
            ["ls-tree", "-r", "--name-only", "-z", update["new"]],
        )
    elif base:
        files = git_paths(
            root,
            git_env,
            ["diff", "--name-only", "-z", base, update["new"]],
        )
    else:
        files = []
    if files is None:
        error("could not determine files affected by the push")
        return 1
    if not files:
        files = [os.fsencode(NO_FILES_SENTINEL)]

    checker_env = {
        "PRE_COMMIT_FROM_REF": base or ZERO_COMMIT,
        "PRE_COMMIT_TO_REF": update["new"],
        "PRE_COMMIT_ORIGIN": base or ZERO_COMMIT,
        "PRE_COMMIT_SOURCE": update["new"],
        "PRE_COMMIT_LOCAL_BRANCH": "refs/heads/{0}".format(
            update["bookmark"]
        ),
        "PRE_COMMIT_REMOTE_BRANCH": "refs/heads/{0}".format(
            update["bookmark"]
        ),
        "PRE_COMMIT_REMOTE_NAME": remote,
        "PRE_COMMIT_REMOTE_URL": remote_url(root, git_env, remote),
    }
    return run_checker(
        real_jj,
        globals_,
        root,
        "pre-push",
        ["--files"] + [os.fsdecode(path) for path in files],
        checker_env=checker_env,
    )


def handle_push(real_jj, args, command_index, globals_, root):
    if not installed_hook(root, "pre-push") and not checker_config(root):
        exec_real(real_jj, args)
    push_args = args[command_index + 2:]
    returncode, output = run_jj(
        real_jj,
        list(globals_) + ["git", "push", "--dry-run"] + push_args,
        cwd=root,
        capture=True,
    )
    if returncode != 0:
        if output:
            sys.stderr.buffer.write(output)
        return returncode

    updates = parse_push_updates(output or b"")
    if not updates:
        if output and b"Changes to push to " in output:
            error("could not understand jj git push --dry-run output; refusing to push")
            return 1
        exec_real(real_jj, args)

    originals = change_ids(real_jj, globals_, root, "@")
    if not originals:
        error("could not identify the current JJ change")
        return 1
    original = originals[0]
    operation = current_operation(real_jj, globals_, root)
    if not operation:
        error("could not identify the operation before pre-push validation")
        return 1
    keep = "jj-hooks-keep-{0}".format(uuid.uuid4().hex)
    created_keep = False
    failure = 0
    cleanup_failure = 0
    before_hook = None
    try:
        returncode, unused_output = run_jj(
            real_jj,
            list(globals_) + ["bookmark", "create", keep, "-r", original,
                              "--quiet"],
            cwd=root,
        )
        if returncode != 0:
            return returncode
        created_keep = True

        for update in updates:
            if update["type"] != "delete":
                returncode, unused_output = run_jj(
                    real_jj,
                    list(globals_) + ["new", update["new"], "--quiet"],
                    cwd=root,
                )
                if returncode != 0:
                    failure = returncode
                    break
            working_commits = commit_ids(real_jj, globals_, root, "@")
            if not working_commits:
                failure = 1
                error("could not snapshot the working copy before pre-push validation")
                break
            before_hook = working_commits[0]
            returncode = run_pre_push_stage(
                real_jj, globals_, root, update
            )
            unused_hook_commit, hook_paths = snapshot_hook_changes(
                real_jj, globals_, root, before_hook
            )
            if hook_paths is None:
                returncode = returncode or 1
            elif hook_paths and returncode == 0:
                returncode = 1
                error("pre-push hook modified files; refusing to push")
            if returncode != 0:
                failure = returncode
                break
    finally:
        if failure:
            if before_hook:
                rollback_failed_hook(
                    real_jj, globals_, root, operation, before_hook,
                    "pre-push validation"
                )
            else:
                returncode, unused_output = run_jj(
                    real_jj, ["op", "restore", operation], cwd=root
                )
                if returncode != 0:
                    cleanup_failure = returncode
                    error("could not restore the operation before pre-push validation")
        else:
            returncode, unused_output = run_jj(
                real_jj,
                list(globals_) + ["edit", original, "--quiet"],
                cwd=root,
            )
            if returncode != 0:
                cleanup_failure = returncode
                error("could not restore the original JJ working copy")
            if created_keep:
                returncode, unused_output = run_jj(
                    real_jj,
                    list(globals_) + ["bookmark", "forget", keep, "--quiet"],
                    cwd=root,
                )
                if returncode != 0 and cleanup_failure == 0:
                    cleanup_failure = returncode
                    error("could not remove the temporary JJ bookmark {0}".format(
                        keep
                    ))

    if failure:
        return failure
    if cleanup_failure:
        return cleanup_failure
    exec_real(real_jj, args)
    return 0


def main():
    real_jj = resolve_real_jj()
    if not real_jj:
        return 127
    args = sys.argv[1:]
    if os.environ.get(ACTIVE_ENV) or os.environ.get("COMPLETE"):
        exec_real(real_jj, args)
    if args and args[0] == "--":
        exec_real(real_jj, args[1:])

    command_index, command = split_command(args)
    if command not in ("commit", "describe", "split", "git"):
        exec_real(real_jj, args)

    globals_ = global_args(args, command_index)
    root = workspace_root(real_jj, globals_)
    if not root:
        exec_real(real_jj, args)

    if command == "commit":
        return handle_commit(
            real_jj, args, command_index, globals_, root
        )
    if command == "describe":
        return handle_describe(
            real_jj, args, command_index, globals_, root
        )
    if command == "split":
        return handle_split(
            real_jj, args, command_index, globals_, root
        )
    if command == "git":
        if command_index + 1 < len(args) and args[command_index + 1] == "push":
            return handle_push(
                real_jj, args, command_index, globals_, root
            )
        exec_real(real_jj, args)
    return 0


if __name__ == "__main__":
    sys.exit(relay_signal(main()))
