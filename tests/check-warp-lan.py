#!/usr/bin/env python3
import importlib.machinery
import sys
sys.dont_write_bytecode = True
import json
import ipaddress
from pathlib import Path
import unittest
from unittest.mock import patch

root = Path(__file__).resolve().parents[1]
m = importlib.machinery.SourceFileLoader('lan', str(root/'dot_local/bin/executable_warp-lan-priority')).load_module()

class Routes(unittest.TestCase):
    def test_local_priority_does_not_bypass_mesh_or_internet(self):
        routes = [dict(dst='192.168.1.0/24',dev='eth0',protocol='kernel'),
                  dict(dst='10.42.0.0/24',dev='robot',protocol='kernel'),
                  dict(dst='default',dev='eth0',protocol='dhcp'),
                  dict(dst='100.96.0.0/12',dev='CloudflareWARP',protocol='kernel'),
                  dict(dst='100.96.0.0/12',dev='robot',protocol='kernel'),
                  dict(dst='172.17.0.0/16',dev='docker0',protocol='kernel',flags=['linkdown'])]
        self.assertEqual(m.connected(routes), {'192.168.1.0/24','10.42.0.0/24'})
    def test_interface_changes_remove_old_rules(self):
        def run(*args):
            if args[1] == '-6': return '[]'
            if 'route' in args: return json.dumps([dict(dst='10.42.0.0/24',dev='robot',protocol='kernel')])
            return json.dumps([dict(dst='192.168.0.0/24',priority=m.PRIORITY,protocol=m.PROTOCOL,table='main')])
        with patch.object(m,'run',side_effect=run),patch.object(m.subprocess,'run') as execute:
            m._reconcile()
            calls=[c.args[0] for c in execute.call_args_list]
            self.assertEqual([c[3] for c in calls],['add','del'])
            self.assertIn('10.42.0.0/24',calls[0]);self.assertIn('192.168.0.0/24',calls[1])
    def test_iproute_separate_prefix_is_idempotent(self):
        def run(*args):
            v4 = args[1] == '-4'
            if 'route' in args:
                return json.dumps([dict(dst='192.168.0.0/24' if v4 else 'fe80::/64',
                                        dev='eth0',protocol='kernel')])
            return json.dumps([dict(priority=m.PRIORITY,protocol=str(m.PROTOCOL),table='main',
                                    dst='192.168.0.0' if v4 else 'fe80::',dstlen=24 if v4 else 64)])
        with patch.object(m,'run',side_effect=run),patch.object(m.subprocess,'run') as execute:
            self.assertTrue(m._reconcile(check=True))
            m._reconcile()
            execute.assert_not_called()
    def test_refuses_unrelated_priority(self):
        def run(*args):
            return '[]' if 'route' in args else json.dumps([dict(priority=m.PRIORITY,table='main',dst='10.0.0.0/8')])
        with patch.object(m,'run',side_effect=run),patch.object(m.subprocess,'run') as execute:
            with self.assertRaises(RuntimeError):m._reconcile()
            execute.assert_not_called()

class Policy(unittest.TestCase):
    def test_exclusions_keep_home_lan_and_mesh_tunneled(self):
        policy = importlib.machinery.SourceFileLoader('policy', str(root/'dot_local/bin/executable_cloudflare-network-policy')).load_module()
        networks = [ipaddress.ip_network(n['address']) for n in policy.exclusions()]
        for value, expected in [('192.168.0.1',True),('192.168.1.50',False),
                                ('192.168.255.254',True),('100.64.0.1',True),
                                ('100.96.0.27',False),('100.112.0.1',True),
                                ('1.1.1.1',False),('2606:4700:cf1:1000::c',False),
                                ('fd00::1',True),('198.41.192.167',True)]:
            ip=ipaddress.ip_address(value)
            self.assertEqual(any(ip.version==n.version and ip in n for n in networks),expected,value)

unittest.main()
