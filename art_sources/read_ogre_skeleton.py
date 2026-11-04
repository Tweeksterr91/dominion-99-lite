import struct,json,sys
from pathlib import Path
source_path=Path(sys.argv[1]);s=source_path.read_bytes();p=s.index(b'\n')+1;bones={};parents={};animations={}
def string(p):
 q=s.index(b'\n',p);return s[p:q].decode(),q+1
while p+6<=len(s):
 kind,size=struct.unpack_from('<HI',s,p);start=p;p+=6
 if kind==0x2000:
  name,p=string(p);handle=struct.unpack_from('<H',s,p)[0];p+=2
  pos=struct.unpack_from('<3f',s,p);p+=12;rot=struct.unpack_from('<4f',s,p);p+=16
  scale=(1,1,1)
  if size>36:scale=struct.unpack_from('<3f',s,p);p+=12
  bones[handle]={'name':name,'pos':pos,'rot':rot,'scale':scale}
 elif kind==0x3000:
  a,b=struct.unpack_from('<HH',s,p);parents[a]=b;p+=4
 elif kind==0x4000:
  name,p=string(p);length=struct.unpack_from('<f',s,p)[0];p+=4
  end=start+size;tracks={}
  while p+6<=end:
   tkind,tsize=struct.unpack_from('<HI',s,p);tend=p+tsize;p+=6
   if tkind!=0x4100:raise ValueError(('track',hex(tkind),p))
   bone=struct.unpack_from('<H',s,p)[0];p+=2;keys=[]
   while p+6<=tend:
    kkind,ksize=struct.unpack_from('<HI',s,p);kend=p+ksize;p+=6
    if kkind!=0x4110:raise ValueError(('key',hex(kkind),p))
    time=struct.unpack_from('<f',s,p)[0];p+=4;rot=struct.unpack_from('<4f',s,p);p+=16;pos=struct.unpack_from('<3f',s,p);p+=12
    scale=(1,1,1)
    if ksize>38:scale=struct.unpack_from('<3f',s,p);p+=12
    keys.append({'time':time,'rot':rot,'pos':pos,'scale':scale})
    assert p==kend
   tracks[bone]=keys
   assert p==tend
  animations[name]={'length':length,'tracks':tracks}
  print('Animation',name,length,len(tracks))
 elif kind==0x5000:
  name,p=string(p);p+=4
 else:raise ValueError((hex(kind),size,p))
print('Bones',len(bones),'Parents',len(parents),'Animations',len(animations),'Bytes',p,len(s))
source_path.with_suffix('.json').write_text(json.dumps({'bones':bones,'parents':parents,'animations':animations}))
