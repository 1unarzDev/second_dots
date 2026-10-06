#!/usr/bin/env python3
"""Test startup with unavailable IPC, delayed locking, and a failed display wake."""
import importlib.util
import importlib.machinery
from pathlib import Path
import sys
from types import SimpleNamespace
import unittest
sys.dont_write_bytecode=True
loader=importlib.machinery.SourceFileLoader('startup',str(Path(__file__).resolve().parents[1]/'dot_local/bin/executable_caelestia-startup-lock'))
spec=importlib.util.spec_from_loader(loader.name,loader)
m=importlib.util.module_from_spec(spec);loader.exec_module(m)

class Startup(unittest.TestCase):
    def test_waits_for_ipc_and_true_lock_state_then_wakes(self):
        calls=[];tries=0;states=iter(['false','true']);waits=[]
        def run(*args):
            nonlocal tries
            calls.append(args)
            if args[-1]=='lock':
                tries+=1
                return SimpleNamespace(returncode=1 if tries==1 else 0,stdout='')
            if args[-1]=='isLocked':return SimpleNamespace(returncode=0,stdout=next(states))
            return SimpleNamespace(returncode=0,stdout='ok')
        m.startup_lock(run,waits.append)
        self.assertEqual(calls[0],('hyprctl','-r','dispatch','hl.dsp.dpms({ action = "enable" })'))
        self.assertEqual(calls[-2][-1],'isLocked')
        self.assertEqual(calls[-1],calls[0])
        self.assertEqual(len(waits),2)
    def test_failed_final_wake_is_retried(self):
        wakes=iter([0,1,1,0]);waits=[]
        def run(*args):
            if args[0]=='hyprctl':return SimpleNamespace(returncode=next(wakes),stdout='ok')
            return SimpleNamespace(returncode=0,stdout='true')
        m.startup_lock(run,waits.append)
        self.assertEqual(len(waits),1)

    def test_exit_zero_syntax_error_uses_legacy_wake(self):
        calls=[]
        def run(*args):
            calls.append(args)
            return SimpleNamespace(returncode=0,stdout='error: invalid Lua dispatcher' if len(calls)==1 else 'ok')
        self.assertTrue(m.wake_displays(run))
        self.assertEqual(calls[-1],('hyprctl','-r','dispatch','dpms','on'))

unittest.main()
