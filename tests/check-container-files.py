#!/usr/bin/env python3
"""Unit tests plus opt-in live Docker/SSH round trips in task-owned fixtures."""
import importlib.machinery
import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
import uuid

sys.dont_write_bytecode = True

SCRIPT = Path(__file__).resolve().parents[1] / 'dot_local/bin/executable_cx-container'
loader = importlib.machinery.SourceFileLoader('container_files', str(SCRIPT))
spec = importlib.util.spec_from_loader(loader.name, loader)
m = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = m
loader.exec_module(m)


class Endpoints(unittest.TestCase):
    def test_paths_and_quoting(self):
        ep = m.endpoint('docker://robot/my-container/workspaces/a%20b/%23note.txt')
        self.assertEqual((ep.host, ep.container, ep.path), ('robot', 'my-container', '/workspaces/a b/#note.txt'))
        self.assertIn("'/workspaces/a b/#note.txt'", ep.command(['cat', '--', ep.path])[-1])
        self.assertIsNone(m.endpoint('docker://local/c/tmp/file').host)

    def test_reject_options_and_ambiguous_urls(self):
        for path in ('ssh://-oProxyCommand/x', 'docker://host/-bad/x', 'docker://host/c', 'ssh://h/x?flag', 'ssh://h/%00'):
            with self.assertRaises(ValueError, msg=path):
                m.endpoint(path)

    def test_container_user_and_streaming_command(self):
        ep = m.Endpoint('robot', 'abc123', '/data', 'vscode')
        command = ep.command(['tar', '-xf', '-'], interactive=True)
        self.assertIn('docker exec -i --user vscode abc123', command[-1])
        self.assertIn('BatchMode=yes', command)


@unittest.skipUnless(os.environ.get('CX_CONTAINER_TEST_DOCKER'), 'set CX_CONTAINER_TEST_DOCKER=1 for live fixtures')
class Docker(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.container = 'cx-files-test-' + uuid.uuid4().hex[:10]
        cls.tmp = tempfile.TemporaryDirectory(prefix='cx-files-test-')
        cls.root = Path(cls.tmp.name)
        subprocess.run(['docker', 'run', '-d', '--name', cls.container, '--label', 'devcontainer.metadata=[{"remoteUser":"nobody"}]', 'archlinux:latest', 'sleep', '600'], check=True, stdout=subprocess.DEVNULL)
        subprocess.run(['docker', 'exec', cls.container, 'mkdir', '-p', '/data'], check=True)
        subprocess.run(['docker', 'exec', cls.container, 'chmod', '777', '/data'], check=True)

    @classmethod
    def tearDownClass(cls):
        subprocess.run(['docker', 'rm', '-f', cls.container], check=True, stdout=subprocess.DEVNULL)
        cls.tmp.cleanup()

    def cli(self, *args, ok=True):
        p = subprocess.run([sys.executable, str(SCRIPT), *args], capture_output=True, text=True)
        if ok:
            self.assertEqual(p.returncode, 0, p.stderr)
        else:
            self.assertNotEqual(p.returncode, 0)
        return p

    def ep(self, path):
        return 'docker://local/' + self.container + path

    def test_roundtrip_tree_and_conflict(self):
        tree = self.root / 'tree $; space'
        tree.mkdir(); (tree / 'empty').mkdir()
        (tree / 'binary').write_bytes(bytes(range(256)) * 1000)
        (tree / 'text.txt').write_text('Unicode café\n')
        (tree / 'link').symlink_to('text.txt')
        self.cli('copy', str(tree), self.ep('/data'))
        out = self.root / 'out'; out.mkdir()
        self.cli('copy', self.ep('/data/tree $; space'), str(out))
        self.assertEqual((out / tree.name / 'binary').read_bytes(), (tree / 'binary').read_bytes())
        self.assertEqual(os.readlink(out / tree.name / 'link'), 'text.txt')
        self.assertTrue((out / tree.name / 'empty').is_dir())
        self.cli('copy', str(tree), self.ep('/data'), ok=False)
        self.cli('copy', str(tree), self.ep('/data'), '--overwrite')
        self.cli('copy', self.ep('/data/tree $; space'), self.ep('/data'), '--overwrite', ok=False)
        preview = self.cli('preview', self.ep('/data/tree $; space/text.txt'), '--limit', '4')
        self.assertEqual(preview.stdout, 'Unic')
        self.assertIn('truncated', preview.stderr)

    def test_edit_and_concurrent_change(self):
        source = self.root / 'edit.txt'; source.write_text('original\n')
        self.cli('copy', str(source), self.ep('/data'))
        editor = self.root / 'editor.py'
        editor.write_text('from pathlib import Path\nimport sys\nPath(sys.argv[1]).write_text("edited\\n")\n')
        self.cli('edit', self.ep('/data/edit.txt'), '--editor', f'{sys.executable} {editor}')
        self.assertEqual(self.cli('preview', self.ep('/data/edit.txt')).stdout, 'edited\n')
        editor.write_text('from pathlib import Path\nimport sys,subprocess\nPath(sys.argv[1]).write_text("unsaved\\n")\nsubprocess.run(["docker","exec",'+repr(self.container)+',"sh","-c","printf concurrent > /data/edit.txt"],check=True)\n')
        result = self.cli('edit', self.ep('/data/edit.txt'), '--editor', f'{sys.executable} {editor}', ok=False)
        self.assertIn('Concurrent change', result.stderr)
        self.assertEqual(self.cli('preview', self.ep('/data/edit.txt')).stdout, 'concurrent')
        saved = result.stderr.split('Edited file preserved at ', 1)[1].splitlines()[0]
        self.assertEqual(Path(saved).read_text(), 'unsaved\n'); Path(saved).unlink()

    def test_failed_editor_preserves_changes(self):
        source = self.root / 'failed-editor.txt'; source.write_text('original')
        self.cli('copy', str(source), self.ep('/data'))
        editor = self.root / 'failing-editor.py'
        editor.write_text('from pathlib import Path\nimport sys\nPath(sys.argv[1]).write_text("recovery")\nsys.exit(3)\n')
        result = self.cli('edit', self.ep('/data/failed-editor.txt'), '--editor', f'{sys.executable} {editor}', ok=False)
        saved = result.stderr.split('Edited file preserved at ', 1)[1].splitlines()[0]
        self.assertEqual(Path(saved).read_text(), 'recovery'); Path(saved).unlink()
        self.assertEqual(self.cli('preview', self.ep('/data/failed-editor.txt')).stdout, 'original')

    def test_ssh_roundtrip(self):
        host = os.environ.get('CX_CONTAINER_TEST_SSH')
        if not host:
            self.skipTest('set CX_CONTAINER_TEST_SSH to a trusted SSH alias')
        folder = subprocess.check_output(['ssh', host, 'mktemp -d /tmp/cx-files-test.XXXXXXXX'], text=True).strip()
        remote_container = 'cx-files-remote-' + uuid.uuid4().hex[:10]
        import shlex
        def remote(argv):
            return subprocess.run(['ssh', host, shlex.join(argv)], check=True, stdout=subprocess.DEVNULL)
        remote(['docker', 'run', '-d', '--name', remote_container, 'busybox:latest', 'sleep', '600'])
        remote(['docker', 'exec', remote_container, 'mkdir', '-p', '/data'])
        try:
            src = self.root / 'remote.txt'; src.write_text('remote transfer\n')
            self.cli('copy', str(src), self.ep('/data'))
            self.cli('copy', self.ep('/data/remote.txt'), 'ssh://' + host + folder)
            self.assertEqual(self.cli('preview', 'ssh://' + host + folder + '/remote.txt').stdout, src.read_text())
            remote_ep = 'docker://' + host + '/' + remote_container + '/data'
            self.cli('copy', self.ep('/data/remote.txt'), remote_ep)
            self.assertEqual(self.cli('preview', remote_ep + '/remote.txt').stdout, src.read_text())
            remote_out = self.root / 'remote-container-out'; remote_out.mkdir()
            self.cli('copy', remote_ep + '/remote.txt', str(remote_out))
            self.assertEqual((remote_out / src.name).read_bytes(), src.read_bytes())
            destination = self.root / 'remote-out'; destination.mkdir()
            self.cli('copy', 'ssh://' + host + folder + '/remote.txt', str(destination))
            self.assertEqual((destination / src.name).read_bytes(), src.read_bytes())
        finally:
            remote(['docker', 'rm', '-f', remote_container])
            subprocess.run(['ssh', host, 'python3 -c ' + shlex.quote('import shutil; shutil.rmtree('+repr(folder)+')')], check=True)


if __name__ == '__main__':
    unittest.main()
