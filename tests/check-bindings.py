"""Check the active Hyprland session without executing its key actions."""
import collections,json,os,subprocess
instances=json.loads(subprocess.check_output(['hyprctl','instances','-j']))
if not os.environ.get('HYPRLAND_INSTANCE_SIGNATURE'):
 os.environ['HYPRLAND_INSTANCE_SIGNATURE']=instances[0]['instance']
b=json.loads(subprocess.check_output(['hyprctl','binds','-j']))
assert not subprocess.check_output(['hyprctl','configerrors'],text=True).strip()
checks=[(64,'Escape'),(8,'a'),(9,'m'),(65,'m'),(9,'up'),(9,'down'),(8,'f'),(9,'f'),(65,'l'),(68,'left'),(68,'right'),(64,'left'),(64,'right'),(8,'Tab'),(9,'Tab'),(12,'Tab'),(13,'Tab'),(64,'p'),(9,'p'),(64,'mouse:272'),(64,'mouse:273')]
for mods,key in checks:
 matches=[x for x in b if x['modmask']==mods and x['key'].lower()==key.lower() and not x.get('release')]
 assert len(matches)==1,(mods,key,len(matches))
 if (mods,key) in [(9,'up'),(9,'down')]:assert matches[0]['repeat'] and matches[0]['locked']
assert not any(x['modmask']==8 and x['key'].lower()=='l' for x in b)
print('PASS:',os.uname().nodename,'all requested bindings present; former conflicts have one action; no config errors')
groups=collections.defaultdict(list)
for x in b:groups[(x['submap'],x['modmask'],x['key'].lower(),x.get('keycode',0),x.get('release',False))].append(x)
assert not any(len(v)>1 for v in groups.values()),[k for k,v in groups.items() if len(v)>1]
print('PASS: no duplicate live bindings')
