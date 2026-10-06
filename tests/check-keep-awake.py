#!/usr/bin/env python3
import importlib.util
import importlib.machinery
from pathlib import Path
import sys
import unittest
sys.dont_write_bytecode=True
loader=importlib.machinery.SourceFileLoader('awake',str(Path(__file__).resolve().parents[1]/'dot_local/bin/executable_caelestia-keep-awake'))
spec=importlib.util.spec_from_loader(loader.name,loader)
m=importlib.util.module_from_spec(spec);loader.exec_module(m)

class Awake(unittest.TestCase):
    def test_enabled_survives_shell_absence_and_ipc_failure(self):
        s=m.AwakeState(True)
        self.assertTrue(s.observe(None,lambda:False,lambda:False))
        self.assertTrue(s.observe(1,lambda:None,lambda:True))
    def test_restart_restores_toggle_before_accepting_state(self):
        s=m.AwakeState();self.assertTrue(s.observe(1,lambda:True,lambda:True))
        restored=[]
        self.assertTrue(s.observe(2,lambda:bool(restored),lambda:restored.append(True) or True))
        self.assertEqual(restored,[True])
    def test_failed_restore_keeps_inhibitor_and_retries(self):
        s=m.AwakeState(True)
        self.assertTrue(s.observe(2,lambda:False,lambda:False))
        self.assertIsNone(s.shell_pid)
        self.assertTrue(s.observe(2,lambda:True,lambda:True))
    def test_explicit_disable_releases_awake_state(self):
        s=m.AwakeState(True);s.shell_pid=2
        self.assertFalse(s.observe(2,lambda:False,lambda:True))
        self.assertFalse(s.observe(None,lambda:True,lambda:True))

unittest.main()
