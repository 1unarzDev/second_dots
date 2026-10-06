#!/usr/bin/env bash
set -euo pipefail
# Patch both the generated theme and its source so palette changes preserve this.
python3 - <<'PY'
from pathlib import Path
import re

root = Path.home() / '.config/yazi'
for name in ('theme_template.toml', 'theme.toml'):
    path = root / name
    if not path.is_file():
        continue
    original = path.read_text()
    section = re.search(r'(?ms)^\[status\]\s*\n.*?(?=^\[|\Z)', original)
    if not section:
        continue
    status = section.group()
    # Blank only the inner separators. Outer colored caps remain rounded.
    # Background colors painted as foreground glyphs cannot be transparent.
    for key, edge in (('sep_left', 'close'), ('sep_right', 'open')):
        status = re.sub(
            rf'(?m)(^{key}\s*=\s*\{{[^\n]*?\b{edge}\s*=\s*)"[^"\n]*"',
            r'\1""', status,
        )
    updated = original[:section.start()] + status + original[section.end():]
    if updated != original:
        path.write_text(updated)
PY
