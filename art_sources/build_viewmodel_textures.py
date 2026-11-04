"""Original tileable PBR detail maps for skin, blued steel, cloth and walnut. MIT."""
from pathlib import Path
import numpy as np
from scipy.ndimage import gaussian_filter,sobel
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]/'assets/textures/viewmodel';ROOT.mkdir(parents=True,exist_ok=True)
rng=np.random.default_rng(9909)
n=1024
def noise(scale):
 a=gaussian_filter(rng.normal(size=(n,n)),scale,mode='wrap');return a/max(a.std(),1e-6)
def save(name,a):Image.fromarray(np.uint8(np.clip(a,0,1)*255)).save(ROOT/(name+'.png'))
def maps(name,color,height,rough):
 save(name+'_color',color)
 dx=sobel(height,axis=1,mode='wrap');dy=sobel(height,axis=0,mode='wrap')
 normal=np.dstack((-dx,-dy,np.ones((n,n))));normal/=np.linalg.norm(normal,axis=2,keepdims=True)
 save(name+'_normal',normal*.5+.5);save(name+'_rough',rough)
y,x=np.mgrid[0:n,0:n];broad=noise(20);fine=noise(.65)
freckles=gaussian_filter((rng.random((n,n))>.998).astype(float),1.6,mode='wrap');freckles/=max(freckles.max(),1e-6)
veins=np.exp(-((np.sin(x*.017+np.sin(y*.007)*1.3)+noise(18)*.13)/.025)**2)*.018
skin=np.array([.53,.345,.25])+broad[:,:,None]*np.array([.018,.014,.012])+fine[:,:,None]*.008-freckles[:,:,None]*np.array([.10,.075,.045])-veins[:,:,None]*np.array([.28,.05,-.10])
pores=gaussian_filter((rng.random((n,n))>.96).astype(float),.55,mode='wrap')
creases=np.exp(-(np.sin(y*.038+x*.001)**2)*180)*.012
maps('skin',skin,-pores*.07+fine*.006-creases,np.clip(.64+noise(3)*.035,.4,.85))
scratches=np.zeros((n,n))
for i in range(1700):
 xx=rng.integers(0,n);yy=rng.integers(0,n);length=rng.integers(5,100)
 scratches[yy% n,(np.arange(length)+xx)%n]+=rng.uniform(.02,.12)
steel=np.array([.105,.133,.16])+noise(8)[:,:,None]*.009+noise(.6)[:,:,None]*.003+scratches[:,:,None]*.5
maps('steel',steel,noise(.7)*.004-scratches*.13,np.clip(.34+noise(3)*.025+scratches*.9,.22,.6))
weave=(np.sin(x*np.pi/3)*np.sin(y*np.pi/3))*.025
cloth=np.array([.085,.105,.10])+noise(8)[:,:,None]*.007+weave[:,:,None]*.4
maps('cloth',cloth,weave, np.clip(.88+noise(2)*.025,.7,1))
grain=np.sin(y*.10+noise(24)*.9+np.sin(x*.006)*2)
wood=np.array([.14,.075,.038])+grain[:,:,None]*np.array([.027,.017,.009])+noise(3)[:,:,None]*.004
maps('walnut',wood,grain*.008+noise(.8)*.004,np.clip(.5+noise(10)*.04,.35,.65))
print('Original PBR textures generated:',ROOT)
