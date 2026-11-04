"""Original arena techno and pump-shotgun foley. MIT; no external samples."""
from pathlib import Path
import numpy as np
from scipy import signal
from scipy.io.wavfile import write
import subprocess,tempfile
RATE=24000;OUT=Path(__file__).resolve().parents[1]/'assets/audio'
def wav(name,wave):
 wave=wave/max(1,np.max(np.abs(wave))/.86)
 write(OUT/(name+'.wav'),RATE,np.int16(np.clip(wave,-1,1)*32767))
def encode(name,wave):
 wave=wave/max(1e-6,np.max(np.abs(wave)))*.86
 with tempfile.TemporaryDirectory() as d:
  p=Path(d)/'track.wav';write(p,RATE,np.int16(wave*32767))
  subprocess.run(['ffmpeg','-y','-loglevel','error','-i',str(p),'-c:a','libvorbis','-q:a','4',str(OUT/(name+'.ogg'))],check=True)
 print(name,len(wave)/RATE)
rng=np.random.default_rng(9912)
for name,duration in [('shotgun_shot',.5),('shotgun_pump',.32),('shotgun_load',1.15),('shotgun_ready',.27)]:
 t=np.arange(int(duration*RATE))/RATE;n=rng.normal(size=len(t));wave=np.zeros(len(t))
 if name=='shotgun_shot':
  blast=signal.sosfilt(signal.butter(2,[70,6800],btype='bandpass',fs=RATE,output='sos'),n)
  wave=blast*np.exp(-t*23)*.65+np.sin(2*np.pi*(58*t+2*(1-np.exp(-t*40))))*np.exp(-t*13)*.48
 elif name=='shotgun_pump':
  wave=signal.sosfilt(signal.butter(2,[700,6000],btype='bandpass',fs=RATE,output='sos'),n)*np.sin(np.pi*t/duration)**2*.22
  for start in [.035,.22]:
   u=np.maximum(0,t-start);wave+=(t>=start)*np.exp(-u*70)*np.sin(2*np.pi*1450*u)*.35
 else:
  starts=[.05,.32,.60,.88] if name=='shotgun_load' else [.03,.12]
  for start in starts:
   u=np.maximum(0,t-start);wave+=(t>=start)*np.exp(-u*65)*(n*.18+np.sin(2*np.pi*980*u)*.24)
 wave*=np.minimum(1,t/.001)*np.minimum(1,(duration-t)/.02)
 wav(name,np.tanh(wave*1.4)*.8)
for index,(name,bpm,note) in enumerate([('verdant_circuit',136,38),('cold_reliquary',140,39),('ember_pressure',146,36),('root_signal',134,33),('tidal_relay',138,42)]):
 duration=128*60/bpm;size=round(duration*RATE);t=np.arange(size)/RATE;beat=len(t)/RATE/128;rng=np.random.default_rng(800+index)
 drums=np.zeros(size);bass=np.zeros(size);lead=np.zeros(size)
 def hz(n):return 440*2**((n-69)/12)
 def stamp(target,start,wave):np.add.at(target,(np.arange(len(wave))+int(start*RATE))%size,wave)
 for b in range(128):
  u=np.arange(int(.36*RATE))/RATE
  kick=np.sin(2*np.pi*(46*u+3.0*(1-np.exp(-u*35))))*np.exp(-u*13)
  stamp(drums,b*beat,np.tanh(kick*1.8)*.43)
  if b%4 in [1,3]:
   u=np.arange(int(.17*RATE))/RATE;n=rng.normal(size=len(u));n=signal.sosfilt(signal.butter(2,[800,4800],btype='bandpass',fs=RATE,output='sos'),n)
   stamp(drums,b*beat,n*np.exp(-u*28)*.14)
  for off in [.5]:
   u=np.arange(int(.07*RATE))/RATE;n=signal.sosfilt(signal.butter(2,4800,btype='highpass',fs=RATE,output='sos'),rng.normal(size=len(u)))
   stamp(drums,(b+off)*beat,n*np.exp(-u*65)*.075)
  for off in [.0,.5]:
   u=np.arange(int(beat*.47*RATE))/RATE;root=note+[0,0,3,-2][(b//32)%4]
   tone=np.sin(2*np.pi*hz(root)*u)+.24*signal.sawtooth(2*np.pi*hz(root)*u)
   stamp(bass,(b+off)*beat,np.tanh(tone*1.4)*np.sin(np.pi*np.arange(len(u))/len(u))**2*.25)
  if b%2==0:
   u=np.arange(int(beat*1.6*RATE))/RATE;pitch=note+24+[0,7,10,3,0,12,7,5][(b//2+index)%8]
   tone=np.sin(2*np.pi*hz(pitch)*u)+.18*np.sin(2*np.pi*hz(pitch)*2*u)
   stamp(lead,(b+.25)*beat,tone*np.exp(-u*5)*(1-np.exp(-u*65))*.13)
 pad=np.sin(2*np.pi*round(hz(note+19)*duration)/duration*t)*.065
 center=drums+bass+lead+pad
 left=center+np.roll(lead,int(beat*.75*RATE))*.25
 right=center+np.roll(lead,int(beat*1.25*RATE))*.25
 encode(name,np.column_stack([left,right]))
