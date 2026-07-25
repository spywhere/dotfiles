#!/usr/bin/env python3

"""Reusable SketchyBar Python API helper."""

import json
import os
import shlex
import shutil
import subprocess
import sys
from collections import OrderedDict


class SketchyBar:
    """Main SketchyBar interface."""

    class Error(RuntimeError):
        """Base SketchyBar error."""

    class BindingError(Error):
        """Item binding error."""

    class QueryError(Error):
        """Query failure error."""

    class Item:
        """Unbound or bound SketchyBar item reference."""

        def __init__(self, identifier):
            if not isinstance(identifier, str) or not identifier:
                raise ValueError("identifier must be a non-empty string")
            self._identifier = identifier
            self._bar = None

        @property
        def identifier(self):
            return self._identifier

        def _require_bound(self):
            if self._bar is None:
                raise SketchyBar.BindingError(
                    "item '{}' is not bound".format(self._identifier)
                )

        def _serialize(self, properties, kwargs):
            # Dotted SketchyBar keys (e.g. "icon.font.size") go in the
            # properties dict; plain kwargs are passed as-is.
            if properties and any(key in kwargs for key in properties):
                raise ValueError(
                    "duplicate key between properties and kwargs"
                )
            merged = OrderedDict()
            if properties:
                merged.update(properties)
            merged.update(kwargs)
            return ["{}={}".format(k, v) for k, v in merged.items()]

        def set(self, properties=None, **kwargs):
            self._require_bound()
            args = self._serialize(properties, kwargs)
            self._bar._execute(["--set", self._identifier] + args)
            return self

        def subscribe(self, *events):
            self._require_bound()
            self._bar._execute(
                ["--subscribe", self._identifier] + list(events)
            )
            return self

        def animate(self, curve, duration):
            self._require_bound()
            return SketchyBar.ItemAnimation(self, curve, duration)

        def query(self):
            self._require_bound()
            if self._bar._dry_run:
                raise SketchyBar.QueryError(
                    "dry-run: item '{}' does not exist".format(self._identifier)
                )
            try:
                result = self._bar._execute(
                    ["--query", self._identifier],
                    capture_output=True,
                    text=True,
                    check=True,
                )
            except SketchyBar.Error as exc:
                raise SketchyBar.QueryError(str(exc))
            try:
                return json.loads(result.stdout)
            except (json.JSONDecodeError, ValueError):
                raise SketchyBar.QueryError(
                    "invalid JSON for '{}'".format(self._identifier)
                )

        def get(self, path, default=None):
            try:
                data = self.query()
            except SketchyBar.QueryError:
                return default
            for key in path.split("."):
                if not isinstance(data, dict):
                    return default
                data = data.get(key)
                if data is None:
                    return default
            return data

    class ItemAnimation:
        """Single-item animated set operation."""

        def __init__(self, item, curve, duration):
            self._item = item
            self._curve = curve
            self._duration = duration

        def set(self, properties=None, **kwargs):
            args = self._item._serialize(properties, kwargs)
            self._item._bar._execute(
                ["--animate", self._curve, str(self._duration),
                 "--set", self._item._identifier] + args
            )
            return self._item

    class Animation:
        """Multi-item animation context manager."""

        def __init__(self, bar, curve, duration):
            self._bar = bar
            self._curve = curve
            self._duration = duration
            self._queue = []
            self._active = False

        def __enter__(self):
            self._active = True
            return self

        def set(self, item, properties=None, **kwargs):
            if not self._active:
                raise SketchyBar.BindingError("animation context not active")
            if item._bar is not self._bar:
                raise SketchyBar.BindingError(
                    "item '{}' not bound to this bar".format(
                        item._identifier
                    )
                )
            args = item._serialize(properties, kwargs)
            self._queue.append(["--set", item._identifier] + args)
            return self

        def __exit__(self, exc_type, exc_val, exc_tb):
            self._active = False
            if exc_type is not None or not self._queue:
                return False
            cmd = ["--animate", self._curve, str(self._duration)]
            for segment in self._queue:
                cmd.extend(segment)
            self._bar._execute(cmd)
            return False

    def __init__(self, executable=None, config_dir=None, python_executable=None):
        self._items = {}

        self._dry_run = os.environ.get("SKETCHYBAR_DRY_RUN") == "1"

        if executable is not None:
            self._executable = executable
        elif self._dry_run and shutil.which("sketchybar") is None:
            self._executable = "sketchybar"
        else:
            self._executable = shutil.which("sketchybar")
            if self._executable is None:
                raise self.Error("sketchybar not found in PATH")

        if config_dir is not None:
            self._config_dir = config_dir
        else:
            self._config_dir = os.environ.get("CONFIG_DIR")
            if not self._config_dir:
                if self._dry_run:
                    self._config_dir = os.getcwd()
                else:
                    raise self.Error("CONFIG_DIR is not set")

        self._python_executable = python_executable or sys.executable

    def add(self, item, *, position):
        if not isinstance(item, self.Item):
            raise TypeError("expected SketchyBar.Item")
        if item._bar is not None:
            raise self.BindingError(
                "item '{}' already bound".format(item._identifier)
            )
        if item._identifier in self._items:
            raise self.BindingError(
                "duplicate item '{}'".format(item._identifier)
            )
        self._execute(["--add", "item", item._identifier, position])
        item._bar = self
        self._items[item._identifier] = item
        return item

    def item(self, identifier):
        """Reference an existing item without emitting --add.

        Use this from plugins to bind to items created by setup scripts.
        The item is bound to this bar so set(), subscribe(), query(), etc.
        work without re-adding it.
        """
        if identifier in self._items:
            return self._items[identifier]
        new_item = self.Item(identifier)
        new_item._bar = self
        self._items[identifier] = new_item
        return new_item

    def animate(self, curve, duration):
        return self.Animation(self, curve, duration)

    def python_plugin(self, path):
        """Return a shell-quoted ``python3 <path>`` string for SketchyBar's ``script=``."""
        if not os.path.isabs(path):
            path = os.path.join(self._config_dir, path)
        return "{} {}".format(
            shlex.quote(self._python_executable),
            shlex.quote(path),
        )

    def add_event(self, name):
        """Register a custom SketchyBar event. Emits --add event <name>. Returns self."""
        self._execute(["--add", "event", name])
        return self

    def add_bracket(self, name, regex):
        """Add a bracket grouping items matching <regex> (passed verbatim, e.g. '/foo.*/').

        Emits --add bracket <name> <regex>. Returns self.
        """
        self._execute(["--add", "bracket", name, regex])
        return self

    def move(self, item, *, after=None, before=None):
        """Move an item after/before another. Pass exactly one of after/before.

        Accepts an Item or a string id. Returns self.
        """
        if (after is None) == (before is None):
            raise ValueError("exactly one of 'after' or 'before' is required")
        identifier = item.identifier if isinstance(item, SketchyBar.Item) else item
        other = after if after is not None else before
        other_id = other.identifier if isinstance(other, SketchyBar.Item) else other
        direction = "after" if after is not None else "before"
        self._execute(["--move", identifier, direction, other_id])
        return self

    def remove(self, target):
        """Remove an item or bracket. Accepts an Item or a string id (brackets are strings).

        Emits --remove <id>. Returns self.
        """
        identifier = target.identifier if isinstance(target, SketchyBar.Item) else target
        self._execute(["--remove", identifier])
        return self

    def _execute(self, args, check=True, **kwargs):
        command = [self._executable] + args
        if self._dry_run:
            quoted = " ".join(shlex.quote(str(a)) for a in command)
            print(quoted)
            return subprocess.CompletedProcess(
                args=command, returncode=0, stdout="", stderr=""
            )
        try:
            return subprocess.run(command, check=check, **kwargs)
        except FileNotFoundError:
            raise self.Error("'{}' not found".format(self._executable))
        except subprocess.CalledProcessError as exc:
            raise self.Error(
                "command failed (exit {}): {}".format(
                    exc.returncode, " ".join(command)
                )
            )
        except OSError as exc:
            raise self.Error(
                "failed to execute '{}': {}".format(self._executable, exc)
            )
