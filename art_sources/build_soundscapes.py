"""Original looping ambient-industrial music and brown noise. MIT; no samples."""
from pathlib import Path
import numpy as np
from scipy import signal
from scipy.io.wavfile import write
import subprocess,tempfile
RATE=24000
OUT=Path(__file__).resolve().parents[1]/'assets/audio';OUT.mkdir(parents=True,exist_ok=True)
def encode(name,wave):
 wave=np.asarray(wave);wave=wave/max(1e-6,np.max(np.abs(wave)))*.72
 with tempfile.TemporaryDirectory() as tmp:
  path=Path(tmp)/'audio.wav';write(path,RATE,np.int16(np.clip(wave,-1,1)*32767))
  subprocess.run(['ffmpeg','-y','-loglevel','error','-i',str(path),'-c:a','libvorbis','-q:a','3',str(OUT/(name+'.ogg'))],check=True)
 print(name,round(len(wave)/RATE,2),'seconds')
def noise_loop(seconds,seed):
 n=int(seconds*RATE);freq=np.fft.rfftfreq(n,1/RATE);r=np.random.default_rng(seed)
 def channel():
  spectrum=(r.normal(size=len(freq))+1j*r.normal(size=len(freq)))/np.maximum(freq,1)
  spectrum*=((freq/32)**2/(1+(freq/32)**2))/(1+(freq/850)**4)
  spectrum[0]=0
  return np.fft.irfft(spectrum,n)
 return np.column_stack([channel(),channel()])
encode('brown_ambience',noise_loop(16,99))
# 64 beats per map; circular delays and phase-aligned oscillators make seamless loops.
for index,(name,bpm,midi) in enumerate([('verdant_circuit',102,38),('cold_reliquary',108,39),('ember_pressure',114,36),('root_signal',100,33),('tidal_relay',104,42)]):
 seconds=64*60/bpm;n=round(seconds*RATE);duration=n/RATE;t=np.arange(n)/RATE;rng=np.random.default_rng(990+index)
 def osc(hz):return np.sin(2*np.pi*(round(hz*duration)/duration)*t)
 def hz(note):return 440*2**((note-69)/12)
 pad=np.zeros(n)
 for note,level in [(midi,.34),(midi+12,.18),(midi+19,.10),(midi+22,.08),(midi+26,.035)]:
  for cents in [-.035,.035]:pad+=osc(hz(note)+cents)*level
 pad*=.40+.08*np.sin(2*np.pi*t/duration*2)
 beat=duration/64
 bass=np.zeros(n);drums=np.zeros(n);arp=np.zeros(n)
 def stamp(track,start,sound):
  ids=(np.arange(len(sound))+int(start*RATE))%n
  np.add.at(track,ids,sound)
 for b in range(64):
  if b%2==0:
   u=np.arange(int(.32*RATE))/RATE
   kick=np.sin(2*np.pi*(43*u+2.0*(1-np.exp(-u*32))))*np.exp(-u*18)
   stamp(drums,b*beat,kick*.17)
  if b%4==2:
   u=np.arange(int(.20*RATE))/RATE;grain=rng.normal(size=len(u));grain=signal.sosfilt(signal.butter(2,[600,2600],btype='bandpass',fs=RATE,output='sos'),grain)
   stamp(drums,b*beat,grain*np.exp(-u*30)*.055)
  if b%2==1:
   u=np.arange(int(.06*RATE))/RATE;grain=rng.normal(size=len(u));grain=signal.sosfilt(signal.butter(2,4400,btype='highpass',fs=RATE,output='sos'),grain)
   stamp(drums,(b+.5)*beat,grain*np.exp(-u*85)*.019)
  if b%4==0:
   u=np.arange(int(beat*1.8*RATE))/RATE
   note=midi+([0,0,3,-2][b//16])
   stamp(bass,b*beat,np.sin(2*np.pi*hz(note)*u)*(1-np.exp(-u*20))*np.exp(-u*3)*.14)
  if b%2==0:
   u=np.arange(int(beat*2.4*RATE))/RATE;note=midi+24+[0,7,10,3,7,0,5,10][(b//2+index)%8]
   tone=(np.sin(2*np.pi*hz(note)*u)+.13*np.sin(2*np.pi*hz(note)*2*u))*np.exp(-u*4)*(1-np.exp(-u*45))
   stamp(arp,b*beat,tone*.065)
 bed=signal.sosfilt(signal.butter(2,1400,fs=RATE,output='sos'),pad+bass)
 center=bed+drums+arp
 left=center+.18*np.roll(arp,int(.75*beat*RATE))+.08*np.roll(center,int(.37*RATE))
 right=center+.18*np.roll(arp,int(1.25*beat*RATE))+.08*np.roll(center,int(.43*RATE))
 encode(name,np.column_stack([left,right]))
