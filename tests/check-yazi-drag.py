# Exercise the installed Yazi binary and real Ctrl+N binding with a mock dragon-drop.
# Usage: python tests/check-yazi-drag.py [--multiple]
import os,sys,pty,fcntl,termios,struct,tempfile,select,time,json,signal,shutil
from pathlib import Path
root=Path(tempfile.mkdtemp(prefix='yazi-drag-check-'));(root/'bin').mkdir();(root/'files').mkdir();(root/'config').mkdir()
f=root/'files'/'file with spaces.txt';f.write_text('check')
expected=[str(f)]
if '--multiple' in sys.argv:
 second=root/'files'/"second 'quoted' file.txt";second.write_text('check');expected.append(str(second))
for name in ['keymap.toml','yazi.toml']:(root/'config'/name).write_bytes((Path.home()/'.config/yazi'/name).read_bytes())
script=root/'bin/dragon-drop';script.write_text('#!/usr/bin/env python3\nimport os,sys,json\nopen(os.environ["DRAG_CHECK_OUTPUT"],"w").write(json.dumps(sys.argv[1:]))\n');script.chmod(0o755)
pid,fd=pty.fork()
if pid==0:
 os.environ.update({'TERM':'xterm-256color','YAZI_CONFIG_HOME':str(root/'config'),'PATH':str(root/'bin')+':'+os.environ['PATH'],'DRAG_CHECK_OUTPUT':str(root/'result')})
 os.environ['PWD']=str(root/'files');os.chdir(root/'files');os.execvp('yazi',['yazi',str(root/'files')])
fcntl.ioctl(fd,termios.TIOCSWINSZ,struct.pack('HHHH',24,100,0,0))
output=b''
def drain(seconds):
 global output
 deadline=time.monotonic()+seconds
 while time.monotonic()<deadline:
  if select.select([fd],[],[],.1)[0]:
   try:output+=os.read(fd,65536)
   except OSError:break
try:
 os.write(fd,b'\x1b[?1;2c');drain(2)
 if '--multiple' in sys.argv:
  os.write(fd,b'\x01');drain(.5)
 os.write(fd,b'\x0e');drain(2)
 args=json.loads((root/'result').read_text()) if (root/'result').exists() else None
 print('Ctrl+N invoked dragon-drop with:',args)
 assert args and args[:3]==['-x','-i','-T'] and sorted(args[3:])==sorted(expected),'FAIL: selected filenames not passed correctly'
 print('PASS: actual Yazi Ctrl+N forwards hovered/selected filenames intact')
finally:
 os.kill(pid,signal.SIGKILL);os.waitpid(pid,0);os.close(fd);shutil.rmtree(root)
