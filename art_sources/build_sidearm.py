"""Original Dominion '99 viewmodel. Run with Blender --background --python this_file."""
import bpy,math
from pathlib import Path
from mathutils import Vector
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def material(name,color,metal=0,rough=.5,emission=False):
 m=bpy.data.materials.new(name);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
 if emission:p.inputs['Emission Color'].default_value=(*color,1);p.inputs['Emission Strength'].default_value=.8
 return m
steel=material('Machined steel',(.16,.20,.24),.85,.32);black=material('Graphite receiver',(.045,.055,.065),.65,.4);edge=material('Worn steel edges',(.30,.34,.37),.8,.36);rubber=material('Glove and grip',(.022,.025,.028),0,.88);fabric=material('Armored sleeve',(.055,.075,.066),0,.92);cyan=material('Power indicator',(.16,.7,.77),.15,.35,True)
def pos(p):return (p[0],-p[2],p[1])
def cube(name,p,size,mat,bevel=.008):
 bpy.ops.mesh.primitive_cube_add(size=1,location=pos(p));o=bpy.context.object;o.name=name;o.dimensions=(size[0],size[2],size[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 mod=o.modifiers.new('Manufactured edge bevel','BEVEL');mod.width=bevel;mod.segments=3;mod.affect='EDGES';bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
 o.data.materials.append(mat)
 mod=o.modifiers.new('Weighted normals','WEIGHTED_NORMAL');mod.keep_sharp=True;bpy.ops.object.modifier_apply(modifier=mod.name)
 return o
def ellipsoid(name,p,size,mat):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,radius=1,location=pos(p));o=bpy.context.object;o.name=name;o.scale=(size[0],size[2],size[1]);o.data.materials.append(mat)
 for poly in o.data.polygons:poly.use_smooth=True
 return o
def barrel(name,p,radius,length,mat):
 bpy.ops.mesh.primitive_cylinder_add(vertices=32,radius=radius,depth=length,location=pos(p),rotation=(math.pi/2,0,0));o=bpy.context.object;o.name=name;o.data.materials.append(mat)
 mod=o.modifiers.new('Rounded lip','BEVEL');mod.width=.003;mod.segments=3;bpy.ops.object.modifier_apply(modifier=mod.name)
 for poly in o.data.polygons:poly.use_smooth=True
 return o
cube('Receiver',(.15,-.205,-.43),(.13,.115,.32),black,.014)
cube('Slide',(.15,-.155,-.45),(.115,.055,.35),steel,.012)
cube('Grip',(.15,-.285,-.315),(.085,.19,.11),rubber,.024)
barrel('Barrel shroud',(.15,-.187,-.64),.041,.16,steel)
barrel('Muzzle bore',(.15,-.187,-.724),.026,.008,black)
barrel('Bore interior',(.15,-.187,-.73),.013,.005,rubber)
for z in [-.62,-.66,-.70]:barrel('Barrel reinforcement',(.15,-.187,z),.045,.012,edge)
cube('Rear sight',(.15,-.117,-.30),(.07,.026,.03),black,.004)
cube('Front sight',(.15,-.117,-.60),(.028,.025,.024),black,.004)
cube('Power rail',(.15,-.12,-.46),(.018,.008,.17),cyan,.003)
for z in [-.37,-.40,-.43,-.46]:cube('Side cooling slots',(.217,-.192,z),(.008,.035,.012),rubber,.002)
cube('Energy cell',(.15,-.24,-.46),(.095,.04,.16),black,.009)
cube('Cell gauge',(.201,-.24,-.46),(.006,.012,.08),cyan,.002)
for z in [-.32,-.52]:
 o=barrel('Assembly screw',(.219,-.205,z),.009,.006,edge);o.rotation_euler=(0,math.pi/2,0)
ellipsoid('Gloved palm',(.172,-.30,-.285),(.052,.062,.068),rubber)
for i in range(4):
 y=-.246-i*.027
 for j in range(3):ellipsoid('Finger %d joint %d'%(i,j),(.174-j*.023,y,-.369+abs(j-1)*.007),(.018,.014,.022),rubber)
ellipsoid('Thumb',(.098,-.246,-.31),(.018,.032,.036),rubber)
ellipsoid('Sleeve',(.205,-.405,-.19),(.080,.105,.16),fabric)
barrel('Wrist cuff',(.18,-.345,-.25),.069,.05,black)
cube('Forearm plate',(.245,-.38,-.19),(.033,.10,.16),steel,.012)
# Join by material to avoid a draw call for every screw and finger joint.
for mat in list(bpy.data.materials):
 objects=[o for o in bpy.data.objects if o.type=='MESH' and mat in list(o.data.materials)]
 if not objects:continue
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects:o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join()
path=Path(__file__).resolve().parents[1]/'assets/models/sidearm.glb';path.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',export_animations=False)
print('Sidearm exported:',path)
