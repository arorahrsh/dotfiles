#!/usr/bin/env python3
"""Exercise installed Zsh configuration in an isolated, real terminal."""

import argparse
import errno
import fcntl
import os
from pathlib import Path
import pty
import re
import select
import shutil
import signal
import struct
import subprocess
import tempfile
import termios
import time


def timeout_test(_signum, _frame):
    raise TimeoutError("Zsh verification exceeded 180 seconds")


class Shell:
    def __init__(self, executable, env, directory, login=True):
        self.pid, self.fd = pty.fork()
        if self.pid == 0:
            os.chdir(directory)
            os.execve(executable, [executable] + (["-l"] if login else []), env)
        fcntl.ioctl(self.fd, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 120, 0, 0))
        self.buffer = ""

    def send(self, text):
        os.write(self.fd, text.encode())

    def expect(self, pattern, timeout=15):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            match = re.search(pattern, self.buffer)
            if match:
                self.buffer = self.buffer[match.end():]
                return match
            if select.select([self.fd], [], [], 0.1)[0]:
                try:
                    chunk = os.read(self.fd, 65536)
                except OSError as error:
                    if error.errno != errno.EIO:
                        raise
                    break
                if not chunk:
                    break
                self.buffer += chunk.decode(errors="replace")
        raise AssertionError(f"Expected {pattern!r}; terminal output:\n{self.buffer}")

    def check(self, expression):
        # The echoed command contains no numeric marker, unlike its result.
        self.send(expression + '; print -r -- __DOTFILES_STATUS_${?}__\n')
        result = self.expect(r"__DOTFILES_STATUS_(\d+)__")
        assert result.group(1) == "0", expression
        self.expect("DOTFILES-READY> ")

    def close(self):
        try:
            self.send("\x03")
            time.sleep(0.1)
            self.send("exit\n")
            deadline = time.monotonic() + 5
            while time.monotonic() < deadline:
                if os.waitpid(self.pid, os.WNOHANG)[0]:
                    return
                time.sleep(0.05)
            # Interactive shells may ignore SIGTERM; bound test cleanup.
            os.kill(self.pid, signal.SIGKILL)
            os.waitpid(self.pid, 0)
        finally:
            os.close(self.fd)


def verify(repo, plugin_dir, zsh):
    plugin = plugin_dir / "zsh-autocomplete.plugin.zsh"
    assert plugin.is_file(), plugin
    with tempfile.TemporaryDirectory(prefix="dotfiles zsh ") as temporary:
        root = Path(temporary)
        home = root / "home"
        work = root / "work"
        home.mkdir()
        work.mkdir()
        for name in ("test-one", "test-two", "test space", "unrelated"):
            (work / name).mkdir()
        env = {
            "HOME": str(home), "PATH": os.environ["PATH"], "SHELL": zsh,
            "TERM": "tmux-256color", "LANG": "en_US.UTF-8",
            "XDG_CONFIG_HOME": str(home / ".config"),
            "XDG_CACHE_HOME": str(home / ".cache"),
            "XDG_STATE_HOME": str(home / ".local/state"),
            "XDG_DATA_HOME": str(home / ".local/share"),
            "GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": "/dev/null",
            "INSTALL_ZSH": "1", "INSTALL_VIM_PLUGINS": "0",
            "EXPECTED_PLUGIN": str(plugin.resolve().parent),
        }
        print("Installing dotfiles in an isolated home", flush=True)
        result = subprocess.run(["bash", str(repo / "install.sh")], env=env,
                                stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE, text=True, timeout=60)
        if result.returncode:
            raise AssertionError(
                f"Installer exited {result.returncode}:\n{result.stdout}\n{result.stderr}"
            )
        # Run after the real plugin and Starship precmd hooks for a stable marker.
        (home / ".config/zsh/local.zsh").write_text(
            "dotfiles_test_prompt() { PROMPT='DOTFILES-READY> '; RPROMPT=; }\n"
            "precmd_functions+=(dotfiles_test_prompt)\n"
            "alias dotfiles_local_check='print local-loaded'\n"
        )
        print("Testing interactive fallback shells", flush=True)
        for name, overrides in (
            ("missing plugin", {"ZSH_AUTOCOMPLETE_PLUGIN": str(root / "missing")}),
            ("disabled plugin", {"ZSH_AUTOCOMPLETE_PLUGIN": str(plugin),
                                 "DOTFILES_ZSH_AUTOCOMPLETE": "0"}),
        ):
            shell = Shell(zsh, dict(env, **overrides), str(work))
            try:
                shell.expect("DOTFILES-READY> ")
                shell.check("[[ $skip_global_compinit == 1 && $TERM == tmux-256color ]]")
                shell.check("[[ -n ${_comps[git]} && ${_comps[g]} == ${_comps[git]} ]]")
                shell.check("[[ $(bindkey '^[[B') == *history-beginning-search-forward ]]")
                shell.check("(( ! ${+functions[.autocomplete:async:complete]} ))")
            finally:
                shell.close()
            print(f"PASS: {name} retains ordinary completion")

        subprocess.run([zsh, "-i", "-c",
                        "[[ $PROMPT == '%n@%m %~ %# ' ]] && "
                        "(( ! ${+functions[.autocomplete:async:complete]} )) && "
                        "[[ -n ${_comps[git]} ]]"],
                       env=dict(env, TERM="dumb", ZSH_AUTOCOMPLETE_PLUGIN=str(plugin)),
                       stdin=subprocess.DEVNULL, check=True)
        subprocess.run([zsh, "-c",
                        "[[ -z ${skip_global_compinit:-} ]] && "
                        "(( ! ${+functions[compdef]} ))"], env=env, check=True)
        print("PASS: dumb-terminal fallback and non-interactive startup")

        destination = Path(env["XDG_DATA_HOME"]) / "zsh/plugins/zsh-autocomplete"
        destination.parent.mkdir(parents=True)
        destination.symlink_to(plugin_dir, target_is_directory=True)
        shell = Shell(zsh, env, str(work))
        try:
            shell.expect("DOTFILES-READY> ")
            shell.check("[[ ${nameddirs[autocomplete]} == $EXPECTED_PLUGIN ]]")
            shell.check("[[ -n ${_comps[git]} && ${_comps[g]} == ${_comps[git]} ]]")
            shell.check("[[ $(bindkey '^[[B') == *down-line-or-select ]]")
            shell.check("[[ $(bindkey '^[OB') == *down-line-or-select ]]")
            shell.check("[[ $(bindkey '^[[A') == *up-line-or-search ]]")
            shell.check("zstyle -a ':autocomplete::compinit' arguments args && [[ $args == -i ]]")
            shell.check("[[ $TERM == tmux-256color && -n ${aliases[dotfiles_local_check]} ]]")
            shell.send("cd test")
            shell.expect("test-one")
            shell.expect("test-two")
            # Down enters the selection menu. The first Enter accepts the item;
            # the second executes cd. Verify the resulting directory separately.
            shell.send("\x1b[B\n\n")
            shell.expect("DOTFILES-READY> ")
            shell.check("[[ $PWD == */work/test* && -d $PWD ]]")
        finally:
            shell.close()
        print("PASS: live directory suggestions without Tab, arrow selection, and cd")

        shell = Shell(zsh, env, str(work), login=False)
        try:
            shell.expect("DOTFILES-READY> ")
            shell.check("[[ ${nameddirs[autocomplete]} == $EXPECTED_PLUGIN ]]")
            shell.check("[[ -n ${_comps[git]} && ${_comps[g]} == ${_comps[git]} ]]")
            shell.check("[[ $(bindkey '^[[B') == *down-line-or-select ]]")
        finally:
            shell.close()
        print("PASS: non-login interactive shells load autocomplete")



if __name__ == "__main__":
    signal.signal(signal.SIGALRM, timeout_test)
    signal.alarm(180)
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--plugin-dir", type=Path, required=True)
    args = parser.parse_args()
    zsh = shutil.which("zsh")
    if not zsh:
        parser.error("zsh must be installed")
    verify(Path(__file__).resolve().parents[1], args.plugin_dir.resolve(), zsh)
