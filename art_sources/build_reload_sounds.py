"""Original mechanical reload foley, synthesized without samples. MIT."""
from pathlib import Path
import numpy as np
from scipy.signal import butter,sosfilt
from scipy.io.wavfile import write
out=Path(__file__).resolve().parents[1]/'assets/audio';out.mkdir(exist_ok=True)
rate=24000;rng=np.random.default_rng(997)
def click(t,start,decay,freq,gain):
 u=np.maximum(t-start,0);gate=(t>=start)
 return gate*np.exp(-u*decay)*(np.sin(2*np.pi*freq*u)+.35*np.sin(2*np.pi*freq*1.73*u))*gain
for name,duration in [('reload_lower',.48),('reload_raise',.23)]:
 t=np.arange(int(duration*rate))/rate
 noise=sosfilt(butter(2,[500,5200],btype='bandpass',fs=rate,output='sos'),rng.normal(size=len(t)))
 if name=='reload_lower':
  wave=noise*np.sin(np.pi*np.clip(t/duration,0,1))**2*.16
  wave+=click(t,.035,95,1600,.22)+click(t,.19,60,580,.26)+click(t,.31,90,2200,.14)
 else:
  wave=noise*np.exp(-t*28)*.18+click(t,.015,65,1050,.32)+click(t,.09,95,2450,.12)
 wave*=np.minimum(1,t/.003)*np.minimum(1,(duration-t)/.02)
 wave=np.tanh(wave*1.4)*.7
 write(out/(name+'.wav'),rate,np.int16(np.clip(wave,-1,1)*32767))
 print(name,duration,'seconds, peak',round(float(np.max(np.abs(wave))),3))
