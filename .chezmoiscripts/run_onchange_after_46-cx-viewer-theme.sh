#!/usr/bin/env bash
# Preserve the viewer's palette for cx-native commands without changing ordinary terminals.
set -euo pipefail
command -v python3 >/dev/null || exit 0
python3 - <<'PY'
import os, pathlib, stat, tempfile
path = pathlib.Path.home() / '.config/fish/config.fish'
if not path.is_file() or path.is_symlink():
    raise SystemExit(0)
info = path.stat()
if info.st_uid != os.getuid() or info.st_nlink != 1:
    raise SystemExit('cx theme guard: refusing foreign or hard-linked Fish config')
old = '    cat ~/.local/state/caelestia/sequences.txt 2> /dev/null'
new = '''    # cx-native commands share the viewer terminal; keep its palette.
    if not set -q CX_VIEWER_THEME
        cat ~/.local/state/caelestia/sequences.txt 2> /dev/null
    end'''
data = path.read_bytes()
if new.encode() in data:
    raise SystemExit(0)
if data.count(old.encode()) != 1:
    # Other themes/configurations are outside this targeted integration.
    raise SystemExit(0)
backup_root = pathlib.Path.home() / '.local/state/cx'
backup_root.mkdir(mode=0o700, parents=True, exist_ok=True)
if backup_root.is_symlink() or backup_root.stat().st_uid != os.getuid():
    raise SystemExit('cx theme guard: refusing foreign backup directory')
fd, backup = tempfile.mkstemp(prefix='fish-theme-before-', dir=backup_root)
with os.fdopen(fd, 'wb') as stream:
    stream.write(data)
fd, temp = tempfile.mkstemp(prefix='.cx-theme-', dir=path.parent)
try:
    with os.fdopen(fd, 'wb') as stream:
        stream.write(data.replace(old.encode(), new.encode()))
        stream.flush()
        os.fsync(stream.fileno())
        os.fchmod(stream.fileno(), stat.S_IMODE(info.st_mode))
    def identity(value):
        # Reading can update atime; compare only identity/mutation metadata.
        return (value.st_dev, value.st_ino, value.st_mode, value.st_uid,
                value.st_gid, value.st_nlink, value.st_size,
                value.st_mtime_ns, value.st_ctime_ns)
    if path.is_symlink() or identity(path.stat()) != identity(info):
        raise SystemExit('cx theme guard: Fish config changed; leaving it untouched')
    os.replace(temp, path)
finally:
    if os.path.exists(temp): os.unlink(temp)
print('cx viewer-theme guard applied; previous Fish config saved privately')
PY
