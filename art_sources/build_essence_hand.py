"""Original open glove for the essence-pull ability. MIT."""
import bpy,math
from pathlib import Path
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def mat(name,color,metal=0,rough=.8,glow=False):
 m=bpy.data.materials.new(name);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
 if glow:p.inputs['Emission Color'].default_value=(*color,1);p.inputs['Emission Strength'].default_value=1
 return m
glove=mat('Essence glove',(.028,.034,.038));sleeve=mat('Essence sleeve',(.06,.075,.07));plate=mat('Essence armor',(.15,.19,.22),.7,.35);blue=mat('Essence focus',(.14,.62,1),.1,.35,True)
def sphere(name,pos,scale,material):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,radius=1,location=(pos[0],-pos[2],pos[1]));o=bpy.context.object;o.name=name;o.scale=(scale[0],scale[2],scale[1]);o.data.materials.append(material)
 for p in o.data.polygons:p.use_smooth=True
sphere('Open palm',(0,0,0),(.053,.064,.025),glove)
for i,length in enumerate([.085,.105,.098,.075]):
 x=-.043+i*.028
 sphere('Finger lower',(x,.058+length*.23,-.005),(.012,length*.28,.013),glove)
 sphere('Finger upper',(x,.058+length*.64,-.014),(.010,length*.25,.011),glove)
sphere('Thumb',(-.071,-.008,-.005),(.031,.017,.017),glove)
sphere('Sleeve',(0,-.17,.075),(.063,.14,.065),sleeve)
sphere('Wrist',(0,-.076,.025),(.055,.035,.039),plate)
sphere('Focus',(0,.005,-.028),(.021,.026,.006),blue)
for material in list(bpy.data.materials):
 objects=[o for o in bpy.data.objects if o.type=='MESH' and material in list(o.data.materials)]
 if not objects:continue
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects:o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join()
path=Path(__file__).resolve().parents[1]/'assets/models/essence_hand.glb'
bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',export_animations=False)
print(path)
