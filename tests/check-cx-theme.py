#!/usr/bin/env python3
"""Scoped Caelestia/cx integration; no real configuration is touched."""
import os
import pathlib
import shutil
import subprocess
import tempfile

script = pathlib.Path(__file__).resolve().parents[1] / ".chezmoiscripts/run_onchange_after_46-cx-viewer-theme.sh"
with tempfile.TemporaryDirectory(prefix="cx-theme-") as tmp:
    root = pathlib.Path(tmp)
    config = root / ".config/fish"
    config.mkdir(parents=True)
    file = config / "config.fish"
    file.write_text("if status is-interactive\n    cat ~/.local/state/caelestia/sequences.txt 2> /dev/null\nend\n")
    os.utime(file, (1, file.stat().st_mtime))  # Reading must not cause a false race.
    state = root / ".local/state/caelestia"
    state.mkdir(parents=True)
    (state / "sequences.txt").write_bytes(b"\x1b]4;1;rgb:12/34/56\x07")
    env = dict(os.environ, HOME=tmp, XDG_CONFIG_HOME=str(root / ".config"))
    env.pop("CX_VIEWER_THEME", None)
    subprocess.run(["bash", str(script)], env=env, check=True)
    first = file.read_bytes()
    subprocess.run(["bash", str(script)], env=env, check=True)
    assert file.read_bytes() == first
    backups = list((root / ".local/state/cx").glob("fish-theme-before-*"))
    assert len(backups) == 1 and backups[0].stat().st_mode & 0o077 == 0
    if shutil.which("fish"):
        normal = subprocess.check_output(["fish", "-i", "-c", "printf OK"], env=env)
        themed = subprocess.check_output(["fish", "-i", "-c", "printf OK"], env=dict(env, CX_VIEWER_THEME="1"))
        assert b"\x1b]4;" in normal and b"\x1b]" not in themed
    else:
        print("BLOCKED: actual Fish output check (Fish unavailable)")
print("PASS: stale atime, idempotence, private backup and scoped guard")
