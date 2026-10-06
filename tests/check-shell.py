#!/usr/bin/env python3
"""Exercise lazy initialization, aliases, failure retries, and literal arguments."""
from pathlib import Path
import os
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory() as temporary:
    tmp = Path(temporary)
    exe = tmp / 'micromamba'
    exe.write_text('''#!/usr/bin/env python3
import os, sys, json
with open(os.environ['HOOK_LOG'], 'a') as f:
    f.write(json.dumps(sys.argv[1:]) + '\\n')
if os.environ.get('FAIL_HOOK') == '1':
    sys.exit(7)
print("function __fish_mamba_wrapper; printf '%s\\\\n' $argv; end")
''')
    exe.chmod(0o755)
    env = dict(os.environ, MAMBA_EXE=str(exe), HOOK_LOG=str(tmp / 'log'),
               XDG_CONFIG_HOME=str(tmp / 'config'), XDG_DATA_HOME=str(tmp / 'data'))
    prefix = f'set -p fish_function_path "{root}/dot_config/fish/functions"; '
    def fish(code):
        return subprocess.run(['fish', '--no-config', '-c', prefix + code], env=env,
                              text=True, capture_output=True, check=True).stdout
    assert fish('functions -q __fish_mamba_wrapper; echo $status').strip() == '1'
    assert not (tmp / 'log').exists()
    result = fish("mamba 'a b' '$(touch nope)' ';'; conda second; micromamba third")
    assert result.splitlines() == ['a b', '$(touch nope)', ';', 'second', 'third'], result
    assert len((tmp / 'log').read_text().splitlines()) == 1
    (tmp / 'log').unlink()
    result = fish('set -gx FAIL_HOOK 1; conda first; echo $status; set -e FAIL_HOOK; conda retry')
    assert result.splitlines() == ['7', 'retry'], result
    assert len((tmp / 'log').read_text().splitlines()) == 2
    result = fish('functions -q _nvm_current; echo $status; nvm --version; nvm current')
    assert result.splitlines() == ['1', 'nvm, version 2.2.18', 'system'], result
    assert not (tmp / 'data/nvm').exists(), 'Startup/version query must not download anything'
    # A selected default activates only on the first Node-family command.
    nvm = tmp / 'nvm/v99.0.0/bin'
    nvm.mkdir(parents=True)
    (tmp / 'nvm/.index').write_text('v99.0.0 latest\n')
    node = nvm / 'node'
    node.write_text('#!/bin/sh\nprintf "selected:%s\\n" "$@"\n')
    node.chmod(0o755)
    result = fish(f'set -g nvm_data "{tmp}/nvm"; set -g nvm_default_version 99; '
                  'node "a b"; node second; echo $nvm_current_version')
    assert result.splitlines() == ['selected:a b', 'selected:second', 'v99.0.0'], result
print('Fish lazy loaders: passed')
