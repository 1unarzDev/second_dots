#!/usr/bin/env bash
set -euo pipefail
# Claude must authenticate even when launched from a terminal/tmux server with
# an old environment. Credentials remain local, outside the chezmoi repository.
python3 - <<'PY'
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

access = Path.home() / '.config/claude/access.fish'
if not access.is_file() or not shutil.which('fish'):
    raise SystemExit(0)

keys = ['ANTHROPIC_CUSTOM_HEADERS', 'ANTHROPIC_BASE_URL', 'ANTHROPIC_AUTH_TOKEN']
# Read only values defined by the private file, without inheriting stale values.
env = {k: v for k, v in os.environ.items() if k not in keys}
code = 'import os,json; print(json.dumps({k:os.environ[k] for k in ' + repr(keys) + ' if k in os.environ}))'
result = subprocess.run(
    ['fish', '--no-config', '-c',
     'if test -f $argv[1]; source $argv[1]; or exit; end; source $argv[2]; or exit; python3 -c $argv[3]',
     str(Path.home() / '.config/caelestia/.env.secrets'), str(access), code],
    env=env, capture_output=True, text=True, check=True,
)
credentials = json.loads(result.stdout)
if not credentials.get('ANTHROPIC_CUSTOM_HEADERS'):
    raise SystemExit('Private Claude Access file has no authentication headers')

settings = Path.home() / '.claude/settings.json'
settings.parent.mkdir(parents=True, exist_ok=True)
data = json.loads(settings.read_text()) if settings.exists() else {}
data.setdefault('env', {}).update(credentials)
updated = json.dumps(data, indent=2) + '\n'
if not settings.exists() or settings.read_text() != updated:
    fd, temporary = tempfile.mkstemp(prefix='.settings-', dir=settings.parent)
    try:
        with os.fdopen(fd, 'w') as handle:
            handle.write(updated)
        os.replace(temporary, settings)
    finally:
        Path(temporary).unlink(missing_ok=True)
settings.chmod(0o600)
PY
