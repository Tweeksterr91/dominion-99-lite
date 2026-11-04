"""Original sawed-off double barrel and plasma scythe. MIT. Reuses original PBR materials."""
from pathlib import Path
source=(Path(__file__).parent/'build_pump_viewmodel.py').read_text()
exec(source.split("weapon=group('Shotgun')")[0])
root=Path(__file__).resolve().parents[1]/'assets/models'
weapon=group('DoubleWeapon')
parent(cube('Break action receiver',(.19,-.19,-.52),(.12,.11,.20),steel,.014),weapon)
parent(cube('Walnut stock',(.22,-.25,-.29),(.09,.12,.30),wood,.025),weapon)
parent(cube('Grip',(.20,-.29,-.45),(.065,.15,.10),wood,.022),weapon)
for x in [.158,.222]:
 parent(barrel('Firing barrel',(x,-.157,-.79),.030,.38,steel),weapon)
 parent(barrel('Open muzzle bore',(x,-.157,-.985),.021,.009,rubber),weapon)
parent(cube('Barrel bridge',(.19,-.154,-.79),(.026,.025,.38),black,.005),weapon)
parent(cube('Short fore-end',(.19,-.235,-.82),(.115,.073,.23),wood,.025),weapon)
parent(cube('Front bead',(.19,-.12,-.94),(.012,.018,.015),edge,.004),weapon)
parent(cube('Breech lever',(.19,-.12,-.47),(.05,.012,.06),black,.004),weapon)
for z in [-.47,-.59]:
 o=barrel('Hinge pin',(.254,-.19,z),.010,.007,edge);o.rotation_euler=(0,math.pi/2,0);parent(o,weapon)
merge(weapon)
bpy.ops.export_scene.gltf(filepath=str(root/'double_barrel.glb'),export_format='GLB',export_animations=False)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
weapon=group('ScytheWeapon')
plasma=material('Plasma edge',(.05,.45,1),.1,.3,True)
plasma.node_tree.nodes.get('Principled BSDF').inputs['Emission Strength'].default_value=2.0
limb('Long alloy haft',(.24,-.48,-.34),(.20,.17,-.88),.021,steel,weapon)
for y,z in [(-.32,-.49),(-.23,-.57),(-.14,-.64)]:
 parent(ellipsoid('Grip wrap',(.22,y,z),(.028,.055,.028),rubber),weapon)
parent(cube('Blade mounting collar',(.20,.16,-.88),(.08,.10,.075),black,.012),weapon)
# A tapered crescent sweeps from the mounting collar toward the screen center.
points=[(.22,.16,-.89),(.18,.28,-.91),(.09,.36,-.94),(-.04,.38,-.96),(-.17,.32,-.98),(-.26,.20,-1.0)]
points.append((-.29,.13,-1.01))
widths=[.065,.08,.075,.055,.035,.012,0.001]
def ribbon(name,lower,upper,mat,depth):
 verts=[];faces=[]
 for a,b in zip(lower,upper):
  for p in [a,b]:
   for dz in [-depth,depth]:verts.append(pos((p[0],p[1],p[2]+dz)))
 for i in range(len(lower)-1):
  j=i*4;k=(i+1)*4
  faces.extend([(j,k,k+2,j+2),(j+1,j+3,k+3,k+1),(j,j+1,k+1,k),(j+2,k+2,k+3,j+3)])
 faces.extend([(0,2,3,1),(len(verts)-4,len(verts)-3,len(verts)-1,len(verts)-2)])
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.materials.append(mat)
 o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o);parent(o,weapon)
 bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
 mod=o.modifiers.new('Forged edge bevel','BEVEL');mod.width=.004;mod.segments=3;bpy.ops.object.modifier_apply(modifier=mod.name)
 bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project();bpy.ops.object.mode_set(mode='OBJECT')
 return o
lower=[(p[0],p[1]-.018,p[2]) for p in points]
upper=[(p[0],p[1]+w,p[2]) for p,w in zip(points,widths)]
ribbon('Forged crescent blade',lower,upper,steel,.010)
ribbon('Continuous plasma cutting edge',[(p[0],p[1]-.031,p[2]) for p in points],lower,plasma,.012)
for y,z in [(-.05,-.71),(.07,-.80)]:limb('Energy collar',(.22,y-.018,z+.015),(.22,y+.018,z-.015),.025,plasma,weapon)
merge(weapon)
bpy.ops.export_scene.gltf(filepath=str(root/'plasma_scythe.glb'),export_format='GLB',export_animations=False)
print('Original double barrel and plasma scythe exported')
