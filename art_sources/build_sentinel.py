"""Original Dominion Sentinel: armored player, original rig and clips. MIT."""
import bpy, math
from pathlib import Path
from mathutils import Vector
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def xyz(p):return (p[0],-p[2],p[1])
def material(name,color,metal=0,rough=.6,emission=False):
 m=bpy.data.materials.new(name);m.use_nodes=True;n=m.node_tree.nodes.get('Principled BSDF');n.inputs['Base Color'].default_value=(*color,1);n.inputs['Metallic'].default_value=metal;n.inputs['Roughness'].default_value=rough
 if emission:n.inputs['Emission Color'].default_value=(*color,1);n.inputs['Emission Strength'].default_value=.8
 return m
armor=material('Ceramic graphite',(.13,.16,.19),.65,.37)
edge=material('Titanium edges',(.30,.34,.37),.8,.31)
suit=material('Carbon undersuit',(.026,.032,.04),.1,.88)
team=material('Team enamel',(.16,.30,.43),.45,.42)
visor=material('Team visor',(.22,.7,1),.3,.25,True)
parts=[]
def bind(o,name,bone,mat):
 o.name=name;o.data.materials.append(mat)
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 v=o.vertex_groups.new(name=bone);v.add(list(range(len(o.data.vertices))),1,'REPLACE')
 for p in o.data.polygons:p.use_smooth=True
 parts.append(o)
 return o
def ellipsoid(name,pos,size,bone,mat):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=10,radius=1,location=xyz(pos));o=bpy.context.object;o.scale=(size[0],size[2],size[1]);return bind(o,name,bone,mat)
def plate(name,pos,size,bone,mat,bevel=.035):
 bpy.ops.mesh.primitive_cube_add(size=1,location=xyz(pos));o=bpy.context.object;o.scale=(size[0],size[2],size[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 mod=o.modifiers.new('Forged soft edges','BEVEL');mod.width=bevel;mod.segments=3;bpy.ops.object.modifier_apply(modifier=mod.name)
 mod=o.modifiers.new('Weighted normals','WEIGHTED_NORMAL');bpy.ops.object.modifier_apply(modifier=mod.name)
 return bind(o,name,bone,mat)
# Foot-level origin. The face and weapon point toward Godot -Z.
bones={'root':((0,0,0),(0,.2,0),None),'hips':((0,.98,0),(0,1.15,0),'root'),'chest':((0,1.15,0),(0,1.66,0),'hips'),'head':((0,1.66,0),(0,2.04,0),'chest')}
for side,x in [('L',-.29),('R',.29)]:
 bones['upper_arm_'+side]=((x,1.62,0),(x*1.28,1.25,0),'chest')
 bones['forearm_'+side]=((x*1.28,1.25,0),(x*1.4,1.02,-.18),'upper_arm_'+side)
 bones['thigh_'+side]=((x*.52,1.02,0),(x*.56,.55,0),'hips')
 bones['shin_'+side]=((x*.56,.55,0),(x*.56,.14,0),'thigh_'+side)
 bones['foot_'+side]=((x*.56,.14,0),(x*.56,.10,-.25),'shin_'+side)
plate('Chest cuirass',(0,1.47,-.02),(.57,.42,.34),'chest',armor,.075)
plate('Gorget',(0,1.70,0),(.34,.12,.27),'chest',edge)
plate('Team breastplate',(0,1.52,-.202),(.43,.21,.065),'chest',team)
plate('Sternum accent',(0,1.50,-.244),(.045,.17,.015),'chest',visor,.008)
ellipsoid('Flexible abdomen',(0,1.18,0),(.215,.21,.145),'hips',suit)
for y in [1.15,1.23,1.31]:plate('Abdomen ribs',(0,y,-.12),(.33,.045,.075),'hips',armor,.016)
plate('Pelvic armor',(0,1.015,-.015),(.42,.17,.29),'hips',armor,.06)
plate('Back power pack',(0,1.46,.24),(.37,.34,.18),'chest',suit)
for x in [-.13,.13]:plate('Rear vent',(x,1.47,.34),(.055,.24,.025),'chest',edge,.012)
ellipsoid('Helmet shell',(0,1.88,-.005),(.165,.205,.165),'head',armor)
plate('Brow',(0,1.98,-.13),(.28,.065,.10),'head',edge,.025)
plate('Visor slit',(0,1.92,-.167),(.25,.06,.035),'head',visor,.018)
plate('Face guard',(0,1.80,-.153),(.205,.14,.075),'head',armor,.04)
for x in [-.054,0,.054]:plate('Respirator vent',(x,1.79,-.196),(.018,.065,.012),'head',suit,.004)
for side,x in [('L',-.29),('R',.29)]:
 arm='upper_arm_'+side;fore='forearm_'+side;thigh='thigh_'+side;shin='shin_'+side;foot='foot_'+side
 ellipsoid('Shoulder seal',(x,1.62,0),(.14,.135,.14),arm,suit)
 plate('Rounded pauldron',(x*1.15,1.64,0),(.235,.22,.33),arm,armor,.075)
 plate('Shoulder team band',(x*1.15,1.67,-.17),(.17,.08,.035),arm,team,.018)
 ellipsoid('Upper arm',(x*1.24,1.41,0),(.095,.20,.10),arm,suit)
 plate('Bicep shell',(x*1.26,1.40,-.08),(.13,.23,.08),arm,armor)
 ellipsoid('Elbow',(x*1.28,1.25,0),(.1,.10,.10),fore,edge)
 ellipsoid('Forearm sleeve',(x*1.35,1.13,-.09),(.09,.15,.11),fore,suit)
 plate('Bracer',(x*1.36,1.14,-.16),(.15,.22,.10),fore,armor)
 ellipsoid('Gauntlet',(x*1.40,1.015,-.18),(.09,.10,.09),fore,suit)
 ellipsoid('Thigh suit',(x*.54,.80,0),(.115,.24,.13),thigh,suit)
 plate('Thigh plate',(x*.54,.80,-.10),(.19,.33,.12),thigh,armor,.055)
 plate('Thigh marking',(x*.54,.87,-.167),(.12,.08,.02),thigh,team,.012)
 ellipsoid('Knee joint',(x*.56,.55,0),(.11,.10,.10),shin,suit)
 plate('Knee shield',(x*.56,.54,-.10),(.19,.18,.11),shin,edge,.045)
 ellipsoid('Lower leg',(x*.56,.34,0),(.09,.18,.095),shin,suit)
 plate('Shin plate',(x*.56,.33,-.07),(.15,.27,.11),shin,armor,.04)
 plate('Armored boot',(x*.56,.10,-.06),(.205,.18,.36),foot,armor,.045)
 plate('Boot sole',(x*.56,.028,-.06),(.21,.045,.37),foot,suit,.015)
# Compact arm-mounted weapon reinforces the ranged silhouette.
plate('Wrist weapon',(.405,1.13,-.29),(.10,.10,.36),'forearm_R',suit,.025)
plate('Weapon barrel',(.405,1.13,-.49),(.065,.065,.10),'forearm_R',edge,.015)
# One skinned mesh, six material surfaces.
bpy.ops.object.select_all(action='DESELECT')
for o in parts:o.select_set(True)
bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();mesh=bpy.context.object;mesh.name='Sentinel armor'
bpy.ops.object.armature_add();rig=bpy.context.object;rig.name='SentinelRig';bpy.ops.object.mode_set(mode='EDIT');rig.data.edit_bones.remove(rig.data.edit_bones[0])
for name,(head,tail,parent) in bones.items():
 b=rig.data.edit_bones.new(name);b.head=xyz(head);b.tail=xyz(tail)
 if parent:b.parent=rig.data.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT');mesh.parent=rig;mod=mesh.modifiers.new('Sentinel skeleton','ARMATURE');mod.object=rig
rig.animation_data_create();bpy.context.scene.render.fps=30
for clip,length in [('Idle',60),('Run',24),('Jump',30)]:
 action=bpy.data.actions.new(clip);rig.animation_data.action=action
 for frame in range(length+1):
  phase=frame/length*math.tau
  for b in rig.pose.bones:b.rotation_mode='XYZ';b.rotation_euler=(0,0,0);b.location=(0,0,0)
  if clip=='Run':
   rig.pose.bones['hips'].location.y=.035*(1-math.cos(phase*2))
   for side,offset in [('L',0),('R',math.pi)]:
    t=phase+offset;rig.pose.bones['thigh_'+side].rotation_euler.x=.60*math.sin(t)
    rig.pose.bones['shin_'+side].rotation_euler.x=-max(0,math.sin(t+1))*.85
    rig.pose.bones['upper_arm_'+side].rotation_euler.x=-.35*math.sin(t)-.2
    rig.pose.bones['forearm_'+side].rotation_euler.x=-.6
   rig.pose.bones['chest'].rotation_euler.y=.055*math.sin(phase)
  elif clip=='Idle':
   rig.pose.bones['chest'].rotation_euler.x=.015*math.sin(phase)
   for side in ['L','R']:rig.pose.bones['forearm_'+side].rotation_euler.x=-.35
  else:
   for side in ['L','R']:
    rig.pose.bones['thigh_'+side].rotation_euler.x=.38
    rig.pose.bones['shin_'+side].rotation_euler.x=-.8
    rig.pose.bones['upper_arm_'+side].rotation_euler.x=-.6
    rig.pose.bones['forearm_'+side].rotation_euler.x=-.6
  for b in rig.pose.bones:
   b.keyframe_insert(data_path='rotation_euler',frame=frame,group=b.name);b.keyframe_insert(data_path='location',frame=frame,group=b.name)
 rig.animation_data.action=None
 track=rig.animation_data.nla_tracks.new();track.name=clip;track.strips.new(clip,0,action)
for b in rig.pose.bones:b.rotation_euler=(0,0,0);b.location=(0,0,0)
bpy.context.scene.frame_set(0)
path=Path(__file__).resolve().parents[1]/'assets/models/sentinel.glb'
bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_yup=True)
print('Original player model exported:',path)
