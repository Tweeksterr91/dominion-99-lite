"""Original matte military Carbon carbine and Warden sniper rifle. MIT."""
from pathlib import Path
source=(Path(__file__).parent/'build_pump_viewmodel.py').read_text()
exec(source.split("weapon=group('Shotgun')")[0])
root=Path(__file__).resolve().parents[1]/'assets/models'
polymer=material('Matte military polymer',(.055,.065,.055),.05,.82)
alloy=material('Parkerized military steel',(.085,.095,.095),.55,.62)
textured(alloy,'steel',.55)
for sniper in [False,True]:
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 weapon=group('MilitaryRifle')
 parent(cube('Upper receiver',(.19,-.18,-.56),(.095,.095,.30),alloy,.009),weapon)
 parent(cube('Lower receiver',(.19,-.245,-.50),(.083,.07,.17),polymer,.008),weapon)
 parent(cube('Pistol grip',(.20,-.29,-.45),(.065,.145,.10),polymer,.018),weapon)
 parent(cube('Adjustable stock',(.22,-.23,-.27),(.09,.12,.25),polymer,.014),weapon)
 parent(cube('Cheek rest',(.22,-.16,-.29),(.09,.04,.18),rubber,.01),weapon)
 parent(cube('Butt pad',(.22,-.23,-.14),(.095,.135,.022),rubber,.008),weapon)
 mag=cube('Detachable box magazine',(.19,-.34,-.61),(.070,.16 if sniper else .21,.10),polymer,.008);mag.rotation_euler.x=.13;parent(mag,weapon)
 for y in [-.29,-.33,-.37]:parent(cube('Magazine reinforcement',(.19,y,-.61),(.077,.012,.105),black,.003),weapon)
 parent(cube('Free-floating handguard',(.19,-.19,-.86),(.080,.085,.32),polymer,.009),weapon)
 length=.48 if sniper else .26;end=-1.43 if sniper else -1.24
 parent(barrel('Precision steel barrel',(.19,-.157,end+length*.5),.016 if sniper else .014,length,alloy),weapon)
 parent(barrel('Muzzle brake',(.19,-.157,end),.024,.065,black),weapon)
 parent(barrel('Dark muzzle bore',(.19,-.157,end-.035),.014,.005,rubber),weapon)
 for z in [-.74,-.80,-.86,-.92,-.98]:
  parent(cube('Handguard side recess',(.233,-.185,z),(.004,.023,.035),rubber,.003),weapon)
  parent(cube('Picatinny rail lug',(.19,-.128,z),(.048,.012,.013),alloy,.003),weapon)
 parent(cube('Ejection port',(.239,-.175,-.56),(.005,.035,.095),rubber,.003),weapon)
 parent(cube('Charging handle',(.19,-.13,-.43),(.13,.018,.026),alloy,.004),weapon)
 for z in [-.48,-.62]:
  o=barrel('Receiver pin',(.24,-.21,z),.006,.005,steel);o.rotation_euler=(0,math.pi/2,0);parent(o,weapon)
 if sniper:
  parent(barrel('Magnified optic',(.19,-.055,-.64),.037,.34,black),weapon)
  for z in [-.83,-.45]:parent(barrel('Recessed optic lens',(.19,-.055,z),.031,.008,rubber),weapon)
  for z in [-.52,-.72]:parent(cube('Optic mount',(.19,-.102,z),(.068,.06,.045),alloy,.005),weapon)
  parent(cube('Elevation turret',(.19,-.006,-.61),(.036,.03,.036),black,.004),weapon)
  limb('Folded bipod left',(.15,-.23,-.92),(.13,-.25,-1.13),.010,alloy,weapon)
  limb('Folded bipod right',(.23,-.23,-.92),(.25,-.25,-1.13),.010,alloy,weapon)
 else:
  parent(cube('Rear aperture sight',(.19,-.105,-.48),(.055,.035,.035),black,.004),weapon)
  parent(cube('Front iron sight',(.19,-.105,-1.00),(.025,.04,.025),black,.004),weapon)
 merge(weapon)
 bpy.ops.export_scene.gltf(filepath=str(root/('warden_sniper.glb' if sniper else 'carbon_carbine.glb')),export_format='GLB',export_animations=False)
print('Original military rifles exported; no emissive materials')
