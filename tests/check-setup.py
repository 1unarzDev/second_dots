"""Exercise setup orchestration against fixtures, never the live system."""
import json
import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import unittest
import zipfile

SOURCE = Path(__file__).resolve().parents[1]


def render(name, data=None):
    args = ['chezmoi', '--source', str(SOURCE), 'execute-template']
    if data:
        args += ['--override-data', json.dumps(data)]
    return subprocess.check_output(args, input=(SOURCE / '.chezmoiscripts' / name).read_bytes()).decode()


class SetupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='chezmoi-setup-check-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.env = os.environ | {'PATH': str(self.bin) + ':' + os.environ['PATH'],
                                 'FIXTURE_ROOT': str(self.root), 'XDG_STATE_HOME': str(self.root / 'state')}

    def command(self, name, code):
        path = self.bin / name
        path.write_text('#!/usr/bin/env python3\n' + code)
        path.chmod(0o755)

    def bash(self, script):
        return subprocess.run(['bash'], input=script, env=self.env,
                              text=True, capture_output=True)

    def assert_ok(self, result):
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_services_enable_active_units_and_start_static_units(self):
        self.command('systemctl', '''import os,sys,json
from pathlib import Path
root=Path(os.environ['FIXTURE_ROOT'])
with (root/'calls').open('a') as log: log.write(json.dumps(sys.argv[1:])+'\\n')
a=sys.argv[1:]
if a[0]=='--user': a=a[1:]
if a[0]=='is-enabled':
 state={'active-but-disabled':'disabled','static-inactive':'static','masked-unit':'masked'}[a[1]]
 print(state);sys.exit(0 if state=='static' else 1)
if a[0]=='is-active':sys.exit(0 if a[-1]=='active-but-disabled' else 3)
''')
        self.command('sudo', 'import sys,subprocess\nsys.exit(subprocess.call(sys.argv[1:]))\n')
        common = (SOURCE / '.chezmoitemplates/setup-service.sh').read_text()
        self.assert_ok(self.bash('set -euo pipefail\n' + common +
                                '\nensure_service system active-but-disabled\nensure_service user static-inactive\n'))
        calls = [json.loads(line) for line in (self.root / 'calls').read_text().splitlines()]
        self.assertIn(['enable', 'active-but-disabled'], calls)
        self.assertNotIn(['start', 'active-but-disabled'], calls)
        self.assertIn(['--user', 'start', 'static-inactive'], calls)
        self.assertNotIn(['--user', 'enable', 'static-inactive'], calls)
        self.assertNotEqual(self.bash('set -e\n' + common + '\nensure_service system masked-unit').returncode, 0)

    def test_post_clone_failure_is_retried_on_existing_checkout(self):
        remote = self.root / 'remote'
        subprocess.run(['git', 'init', '-q', str(remote)], check=True)
        (remote / 'file').write_text('fixture')
        subprocess.run(['git', '-C', str(remote), 'add', 'file'], check=True)
        subprocess.run(['git', '-C', str(remote), '-c', 'user.name=Fixture', '-c',
                        'user.email=fixture@example.invalid', 'commit', '-qm', 'fixture'], check=True)
        ready = self.root / 'ready'
        script = render('run_after_40-clone-repos.sh.tmpl', {'repos': [{
            'url': str(remote), 'path': '', 'name': 'checkout',
            'post_clone': 'test -f ' + shlex.quote(str(ready)),
        }]}).replace('target="$HOME/', f'target="{self.root}/')
        self.assertNotEqual(self.bash(script).returncode, 0)
        self.assertTrue((self.root / 'checkout/.git').is_dir())
        self.assertFalse(list((self.root / 'checkout/.git').glob('chezmoi-post-clone-*')))
        ready.touch()
        self.assert_ok(self.bash(script))
        self.assertTrue(list((self.root / 'checkout/.git').glob('chezmoi-post-clone-*')))
        ready.unlink()
        self.assert_ok(self.bash(script))

    def test_sine_uses_install_profile_replaces_prefs_and_cleans_up(self):
        cfg = self.root / 'config/zen'
        cfg.mkdir(parents=True)
        active, other = cfg / 'release profile', cfg / 'other'
        active.mkdir(); other.mkdir()
        (cfg / 'profiles.ini').write_bytes(b'[Profile0]\r\nPath=other\r\nIsRelative=1\r\nDefault=1\r\n[InstallABC]\r\nDefault=release profile\r\n')
        (active / 'user.js').write_text('user_pref("browser.tabs.allow_transparent_browser", true);\nuser_pref("unrelated", 17);\n')
        zen = self.root / 'zen-install'
        zen.mkdir(); (zen / 'zen-bin').touch()
        archives = self.root / 'archives'; archives.mkdir()
        for name, files in {
            'program.zip': {'config.js': 'bootloader', 'defaults/pref/config-prefs.js': 'prefs'},
            'profile.zip': {'userChrome.css': '/* fixture */'},
            'engine.zip': {'JS/sine.sys.mjs': '// fixture entry\n', 'JS/core/manager.sys.mjs': '// fixture manager'},
        }.items():
            with zipfile.ZipFile(archives / name, 'w') as archive:
                for path, contents in files.items(): archive.writestr(path, contents)
        self.command('curl', '''import sys,os,shutil
from pathlib import Path
args=sys.argv[1:];url=next(a for a in args if a.startswith('https://'))
shutil.copyfile(Path(os.environ['FIXTURE_ROOT'])/'archives'/url.split('/')[-1],args[args.index('--output')+1])
''')
        self.command('pgrep', 'import sys\nsys.exit(1)\n')
        self.command('sudo', 'import sys,subprocess\nsys.exit(subprocess.call(sys.argv[1:]))\n')
        self.env['XDG_CONFIG_HOME'] = str(self.root / 'config')
        work = self.root / 'work'; work.mkdir(); self.env['TMPDIR'] = str(work)
        script = render('run_after_50-zen-sine.sh.tmpl',
                        {'chezmoi': {'hostname': 'tranquility'}}).replace('/opt/zen-browser-bin', str(zen))
        # An open browser must not prevent later chezmoi stages from running.
        self.command('pgrep', 'import sys\nsys.exit(0)\n')
        open_result = self.bash(script + '\necho later-stage-completed\n')
        self.assert_ok(open_result)
        self.assertIn('deferred', open_result.stdout)
        self.assertIn('later-stage-completed', open_result.stdout)
        self.assertFalse((active / 'chrome').exists())
        stamp = self.root / 'state/chezmoi/zen-sine.fingerprint'
        self.assertFalse(stamp.exists())
        self.command('pgrep', 'import sys\nsys.exit(1)\n')
        self.assert_ok(self.bash(script))
        self.assertTrue(stamp.exists())
        current = self.bash(script)
        self.assert_ok(current)
        self.assertIn('already current', current.stdout)
        content = (active / 'user.js').read_text()
        self.assertEqual(content.count('browser.tabs.allow_transparent_browser'), 1)
        self.assertIn('"browser.tabs.allow_transparent_browser", false', content)
        self.assertIn('"unrelated", 17', content)
        self.assertFalse((other / 'chrome').exists())
        self.assertEqual((active / 'chrome/JS/sine.sys.mjs').read_text().count('// chezmoi-sine-bootstrap-loader'), 1)
        self.assertEqual((zen / 'config.js').read_text(), 'bootloader')
        self.assertFalse(list(work.iterdir()))
        self.command('pgrep', 'import sys\nsys.exit(0)\n')
        stamp.write_text('previous-revision')
        result = self.bash(script)
        self.assert_ok(result)
        self.assertIn('deferred', result.stdout)
        self.assertEqual(stamp.read_text(), 'previous-revision')
        self.assertFalse(list(work.iterdir()))
        # The unchanged stage must retry successfully once the browser closes.
        self.command('pgrep', 'import sys\nsys.exit(1)\n')
        self.assert_ok(self.bash(script))
        self.assertNotEqual(stamp.read_text(), 'previous-revision')
        self.assertFalse(list(work.iterdir()))
        # Reopening during downloads also defers without marking completion.
        stamp.write_text('before-race')
        self.command('pgrep', """import os,sys
from pathlib import Path
count=Path(os.environ['FIXTURE_ROOT'])/'pgrep-count'
n=int(count.read_text())+1 if count.exists() else 1
count.write_text(str(n))
sys.exit(0 if n>=3 else 1)
""")
        result = self.bash(script)
        self.assert_ok(result)
        self.assertIn('Zen opened during setup', result.stdout)
        self.assertEqual(stamp.read_text(), 'before-race')
        self.assertFalse(list(work.iterdir()))

    def test_yazi_preserves_corrupt_cache_and_retries(self):
        cache = self.root / 'cache/yazi/packages'
        cache.mkdir(parents=True)
        (cache / 'damaged').write_text('preserve me')
        self.env['XDG_CACHE_HOME'] = str(self.root / 'cache')
        self.command('ya', """import os,sys
from pathlib import Path
count=Path(os.environ['FIXTURE_ROOT'])/'attempts'
n=int(count.read_text()) if count.exists() else 0
count.write_text(str(n+1))
if n==0:
 print('File name too long (os error 36)',file=sys.stderr);sys.exit(1)
""")
        self.command('git', """import sys
from pathlib import Path
(Path(sys.argv[-1])/'setup.sh').write_text('echo theme-fixture-installed\\n')
""")
        self.assert_ok(self.bash(render('run_onchange_after_45-yazi.sh.tmpl')))
        self.assertEqual((self.root / 'attempts').read_text(), '2')
        backups = list((self.root / 'cache/yazi').glob('packages.backup.*/packages/damaged'))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), 'preserve me')

    def test_arch_install_upgrades_before_installing_packages(self):
        self.command('pacman', '''import os,sys,json
with open(os.environ['FIXTURE_ROOT']+'/calls','a') as f:f.write(json.dumps(sys.argv[1:])+'\\n')
''')
        self.command('sudo', 'import sys,subprocess\nsys.exit(subprocess.call(sys.argv[1:]))\n')
        self.command('yay', 'pass\n')
        self.command('lspci', 'print("00:02.0 0300: 8086:1234")\n')
        self.assert_ok(self.bash(render('run_onchange_before_00-install-packages.sh.tmpl')))
        calls = [json.loads(line) for line in (self.root / 'calls').read_text().splitlines()]
        self.assertEqual(calls[0][0], '-Syu')
        self.assertIn('dart-sass', calls[0]); self.assertIn('swappy', calls[0])
        self.assertNotIn('nvidia-open', calls[0])


if __name__ == '__main__':
    unittest.main()
