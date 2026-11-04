"""Original military-rifle shot synthesis. MIT; no third-party samples."""
from pathlib import Path
import numpy as np
from scipy.signal import butter, sosfilt
from scipy.io.wavfile import write
rng = np.random.default_rng(9912)
rate = 44100
for name, duration, freq in [("carbine_shot", .24, 115), ("sniper_shot", .58, 65)]:
    t = np.arange(int(rate * duration)) / rate
    noise = sosfilt(butter(2, [200, 9000], fs=rate, btype="bandpass", output="sos"), rng.normal(size=len(t)))
    wave = noise * np.exp(-t * (32 if duration < .3 else 15)) * .5 + np.sin(2 * np.pi * freq * t) * np.exp(-t * 22) * .38
    wave += np.sin(2 * np.pi * 1400 * t) * np.exp(-t * 95) * .12
    wave /= max(1, abs(wave).max())
    write(Path(__file__).resolve().parents[1] / f"assets/audio/{name}.wav", rate, np.int16(wave * 29000))
