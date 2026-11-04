"""Original plasma-scythe swing synthesis. MIT."""
from pathlib import Path
import numpy as np
from scipy.signal import butter,sosfilt
from scipy.io.wavfile import write
rate=44100;n=int(rate*.48);t=np.arange(n)/rate;rng=np.random.default_rng(9911)
noise=sosfilt(butter(2,[450,7000],fs=rate,btype='bandpass',output='sos'),rng.normal(size=n))
env=np.sin(np.pi*np.clip(t/.46,0,1))**1.8
wave=(noise*.22+np.sin(2*np.pi*(340*t+360*t*t))*.13)*env*np.exp(-t*2)
wave/=max(1,abs(wave).max())
write(Path(__file__).resolve().parents[1]/'assets/audio/scythe_swing.wav',rate,np.int16(wave*26000))
