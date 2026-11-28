#!/usr/bin/env python3
"""Check preferences behavior with isolated state and mocked macOS commands."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "macos/preferences.sh"
MOCK = r'''
import json
import os
from pathlib import Path
import sys

command = Path(sys.argv[0]).name
args = sys.argv[1:]
state_file = Path(os.environ["PREFS_STATE"])
state = json.loads(state_file.read_text())
if command == "uname":
    print(os.environ.get("PREFS_OS", "Darwin"))
elif command == "defaults":
    action, domain, key = args[:3]
    name = domain + "/" + key
    if action == "read":
        if name not in state:
            sys.exit(1)
        print(state[name])
    elif action == "write":
        if os.environ.get("PREFS_FAIL_WRITE"):
            sys.exit(1)
        value = args[4]
        if args[3] == "-bool":
            if value not in ("true", "false", "yes", "no"):
                sys.exit(2)
            value = "1" if value in ("true", "yes") else "0"
        state[name] = value
        state_file.write_text(json.dumps(state))
    else:
        sys.exit(2)
elif command != "killall":
    sys.exit(2)
with open(os.environ["PREFS_LOG"], "a") as log:
    log.write(json.dumps([command] + args) + "\n")
'''


class PreferencesTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name)
        self.home = root / "home with spaces"
        self.home.mkdir()
        self.screenshots = self.home / "Pictures/Screenshots"
        self.state = root / "state.json"
        self.state.write_text("{}")
        self.log = root / "commands.jsonl"
        self.log.touch()
        binaries = root / "bin"
        binaries.mkdir()
        for name in ("defaults", "killall", "uname"):
            mock = binaries / name
            mock.write_text(f"#!{sys.executable}\n" + MOCK)
            mock.chmod(0o755)
        self.env = dict(os.environ, HOME=str(self.home),
                        PATH=f"{binaries}:{os.environ['PATH']}",
                        PREFS_STATE=str(self.state), PREFS_LOG=str(self.log))

    def invoke(self, *args, success=True):
        result = subprocess.run(["bash", str(SCRIPT), *args], env=self.env,
                                capture_output=True, text=True, timeout=15)
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        return result.stdout

    def mutations(self):
        return [entry for entry in map(json.loads, self.log.read_text().splitlines())
                if entry[0] == "killall" or entry[:2] == ["defaults", "write"]]

    def test_apply_all_and_repeat_without_changes(self):
        self.invoke()
        self.assertEqual(json.loads(self.state.read_text()), {
            "NSGlobalDomain/AppleShowAllExtensions": "1",
            "com.apple.finder/ShowPathbar": "1",
            "com.apple.finder/FXDefaultSearchScope": "SCcf",
            "com.apple.finder/AppleShowAllFiles": "1",
            "com.apple.screencapture/location": str(self.screenshots),
            "com.apple.menuextra.clock/ShowSeconds": "1",
        })
        self.assertTrue(self.screenshots.is_dir())
        mutations = self.mutations()
        self.assertEqual(len(mutations), 7)
        self.assertEqual(mutations[-1], ["killall", "Finder"])
        self.invoke()
        self.assertEqual(self.mutations(), mutations)

    def test_dry_run_has_no_side_effects(self):
        output = self.invoke("--dry-run")
        self.assertEqual(output.count("Would set:"), 6)
        self.assertIn("Would restart Finder once", output)
        self.assertEqual(self.state.read_text(), "{}")
        self.assertFalse(self.screenshots.exists())
        self.assertEqual(self.mutations(), [])

    def test_only_changed_preference_is_written(self):
        self.invoke()
        for key in ("com.apple.menuextra.clock/ShowSeconds", "com.apple.finder/ShowPathbar"):
            with self.subTest(key=key):
                state = json.loads(self.state.read_text())
                state[key] = "0"
                self.state.write_text(json.dumps(state))
                self.log.write_text("")
                self.invoke()
                domain, name = key.split("/")
                expected = [["defaults", "write", domain, name, "-bool", "true"]]
                if domain == "com.apple.finder":
                    expected.append(["killall", "Finder"])
                self.assertEqual(self.mutations(), expected)

    def test_help_invalid_options_and_non_macos_do_not_mutate(self):
        self.invoke("--help")
        self.invoke("--hidden-files", "off", success=False)
        self.env["PREFS_OS"] = "Linux"
        self.invoke(success=False)
        self.assertFalse(self.screenshots.exists())
        self.assertEqual(self.mutations(), [])

    def test_write_failure_stops_execution(self):
        self.env["PREFS_FAIL_WRITE"] = "1"
        self.invoke(success=False)
        self.assertEqual(self.state.read_text(), "{}")
        self.assertEqual(self.mutations(), [])


if __name__ == "__main__":
    unittest.main()
