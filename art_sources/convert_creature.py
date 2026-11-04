import bpy,json,math
from mathutils import Matrix,Vector,Quaternion
from pathlib import Path
import sys
src=Path(sys.argv[sys.argv.index('--')+1]);out=Path(__file__).resolve().parents[1]/'assets/models';out.mkdir(parents=True,exist_ok=True)
data=json.loads((src/'Sinbad.json').read_text());bones={int(k):v for k,v in data['bones'].items()};parents={int(k):int(v) for k,v in data['parents'].items()};anim=data['animations']
arm=bpy.data.objects['Armature'];mesh=bpy.data.objects['Sinbad']
for obj in list(bpy.data.objects):
 if obj not in [arm,mesh]:bpy.data.objects.remove(obj,do_unlink=True)
arm.animation_data_clear()
for b in arm.pose.bones:
 for c in list(b.constraints):b.constraints.remove(c)
 b.rotation_mode='QUATERNION'
for action in list(bpy.data.actions):bpy.data.actions.remove(action)
def quat(v):return Quaternion((v[3],v[0],v[1],v[2]))
def trs(p,q,scale=(1,1,1)):return Matrix.Translation(Vector(p))@q.to_matrix().to_4x4()@Matrix.Diagonal((*scale,1))
local_rest={i:trs(b['pos'],quat(b['rot']),b['scale']) for i,b in bones.items()};world_rest={}
def rest(i):
 if i not in world_rest:world_rest[i]=(rest(parents[i]) if i in parents else Matrix.Identity(4))@local_rest[i]
 return world_rest[i]
for i in bones:rest(i)
C=Matrix.Rotation(math.pi/2,4,'X');Ci=C.inverted()
errors=[]
for i,b in bones.items():
 if b['name'] in arm.data.bones:errors.append(((C@world_rest[i]).translation-arm.data.bones[b['name']].head_local).length)
print('REST ALIGNMENT MAX',max(errors),'ARM MATRIX',arm.matrix_world)
def evaluate(keys,t):
 if len(keys)==1:return keys[0]
 for j in range(1,len(keys)):
  if keys[j]['time']>=t:
   a,b=keys[j-1],keys[j];f=(t-a['time'])/max(.00001,b['time']-a['time'])
   return {'pos':Vector(a['pos']).lerp(Vector(b['pos']),f),'rotq':quat(a['rot']).slerp(quat(b['rot']),f),'scale':Vector(a['scale']).lerp(Vector(b['scale']),f)}
 return keys[-1]
def bake(name,clips,length):
 action=bpy.data.actions.new(name);arm.animation_data_create();arm.animation_data.action=action
 samples=max(2,round(length*30))
 tracks={}
 for clip in clips:tracks.update({int(k):v for k,v in anim[clip]['tracks'].items()})
 for frame in range(samples+1):
  t=frame/30;posed={}
  def pose(i):
   if i not in posed:
    local=local_rest[i]
    if i in tracks:
     v=evaluate(tracks[i],min(t,anim[clips[0]]['length']))
     q=v['rotq'] if 'rotq' in v else quat(v['rot'])
     local=trs(Vector(bones[i]['pos'])+Vector(v['pos']),quat(bones[i]['rot'])@q,Vector(bones[i]['scale'])*Vector(v['scale']))
    posed[i]=(pose(parents[i]) if i in parents else Matrix.Identity(4))@local
   return posed[i]
  desired={}
  for i,b in bones.items():
   if b['name'] in arm.data.bones:desired[i]=C@pose(i)@world_rest[i].inverted()@Ci@arm.data.bones[b['name']].matrix_local
  for i,mat in desired.items():
   bone=arm.pose.bones[bones[i]['name']]
   if i in parents:
    parent=parents[i]
    basis=bone.bone.matrix_local.inverted()@arm.data.bones[bones[parent]['name']].matrix_local@desired[parent].inverted()@mat
   else:basis=bone.bone.matrix_local.inverted()@mat
   bone.matrix_basis=basis
   bone.keyframe_insert('location',frame=frame,group=bone.name)
   bone.keyframe_insert('rotation_quaternion',frame=frame,group=bone.name)
   bone.keyframe_insert('scale',frame=frame,group=bone.name)
 action.use_fake_user=True
 print('BAKED',name,samples+1)
bake('Run',['RunBase','RunTop','HandsClosed'],2/3)
bake('Idle',['IdleBase','IdleTop','HandsRelaxed'],2.0)
bake('Jump',['JumpLoop','HandsClosed'],1.0)
# Rebuild converted Blender Internal materials as modern PBR materials.
for mat in mesh.data.materials:
 mat.use_nodes=True;nodes=mat.node_tree.nodes;nodes.clear();output=nodes.new('ShaderNodeOutputMaterial');bsdf=nodes.new('ShaderNodeBsdfPrincipled');mat.node_tree.links.new(bsdf.outputs['BSDF'],output.inputs['Surface'])
 bsdf.inputs['Roughness'].default_value=.62
 name=mat.name
 if name.endswith('/Body') or name.endswith('/Clothes'):
  tex=nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(src/('sinbad_body.tga' if name.endswith('/Body') else 'sinbad_clothes.tga')),check_existing=True)
  tex.image.pack()
  gray=nodes.new('ShaderNodeRGBToBW');mat.node_tree.links.new(tex.outputs['Color'],gray.inputs[0])
  mix=nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1;mix.inputs[2].default_value=(.68,.73,.77,1) if name.endswith('/Body') else (.27,.30,.33,1)
  mat.node_tree.links.new(gray.outputs[0],mix.inputs[1]);mat.node_tree.links.new(mix.outputs[0],bsdf.inputs['Base Color'])
  # Exporter recognizes direct image inputs; keep original texture but use a grounded tint.
  mat.node_tree.links.new(tex.outputs['Color'],bsdf.inputs['Base Color'])
  bsdf.inputs['Base Color'].default_value=(.35,.42,.4,1)
 elif name.endswith('/Eyes'):
  bsdf.inputs['Base Color'].default_value=(.55,.025,.015,1);bsdf.inputs['Emission Color'].default_value=(.8,.015,.005,1);bsdf.inputs['Emission Strength'].default_value=1.0
 elif name.endswith('/Gold') or name.endswith('/Sheaths'):
  bsdf.inputs['Base Color'].default_value=(.11,.14,.17,1);bsdf.inputs['Metallic'].default_value=.7;bsdf.inputs['Roughness'].default_value=.35
 else:bsdf.inputs['Base Color'].default_value=(.63,.6,.5,1)
for poly in mesh.data.polygons:poly.use_smooth=True
# Normalize to a human-sized silhouette. Ogre coordinates are mapped by the exporter.
root=bpy.data.objects.new('WardenCreature',None);bpy.context.collection.objects.link(root)
bottom=min((mesh.matrix_world @ v.co).z for v in mesh.data.vertices)
arm.parent=root;root.scale=(.2,.2,.2);root.location.z=-bottom*.2
print('NORMALIZED FEET OFFSET',root.location.z)
bpy.context.scene.render.fps=30
arm.animation_data.action=bpy.data.actions['Run'];bpy.context.scene.frame_set(0)
bpy.ops.object.select_all(action='DESELECT');arm.select_set(True);mesh.select_set(True);root.select_set(True);bpy.context.view_layer.objects.active=arm
bpy.ops.export_scene.gltf(filepath=str(out/'warden.glb'),export_format='GLB',export_copyright='Sinbad (c) Zi Ye; CC BY-SA 3.0; adapted for Dominion 99',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,export_frame_range=False,export_nla_strips=True)
print('EXPORTED',out/'warden.glb')
