"""Original single-barrel pump shotgun and anatomical first-person arms. MIT."""
from pathlib import Path
exec((Path(__file__).parent/'build_sidearm.py').read_text().split("cube('Receiver'")[0])
skin=material('Exposed skin',(.42,.245,.15),0,.6);nail=material('Fingernails',(.57,.36,.26),0,.5);wood=material('Oiled walnut',(.095,.075,.055),0,.5)
texture_root=Path(__file__).resolve().parents[1]/'assets/textures/viewmodel'
def textured(mat,prefix,metallic=0):
 nodes=mat.node_tree.nodes;links=mat.node_tree.links;bsdf=nodes.get('Principled BSDF')
 bsdf.inputs['Metallic'].default_value=metallic
 for role,socket in [('color','Base Color'),('rough','Roughness')]:
  tex=nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(texture_root/(prefix+'_'+role+'.png')),check_existing=True)
  if role!='color':tex.image.colorspace_settings.name='Non-Color'
  links.new(tex.outputs['Color'],bsdf.inputs[socket])
 tex=nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(texture_root/(prefix+'_normal.png')),check_existing=True);tex.image.colorspace_settings.name='Non-Color'
 normal=nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=.65
 links.new(tex.outputs['Color'],normal.inputs['Color']);links.new(normal.outputs['Normal'],bsdf.inputs['Normal'])
textured(skin,'skin');textured(steel,'steel',.88);textured(black,'steel',.75);textured(edge,'steel',.9);textured(fabric,'cloth');textured(wood,'walnut')
# Smooth silhouette at close first-person distances.
base_ellipsoid=ellipsoid
def ellipsoid(name,p,size,mat):
 o=base_ellipsoid(name,p,size,mat)
 sub=o.modifiers.new('Anatomical smoothing','SUBSURF');sub.levels=1;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=sub.name)
 return o
def group(name):
 o=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(o);return o
def parent(o,g):
 o.parent=g;return o
def limb(name,a,b,radius,mat,g):
 a=Vector(pos(a));b=Vector(pos(b));o=ellipsoid(name,(0,0,0),(radius,radius,(b-a).length*.55),mat)
 o.location=(a+b)*.5;o.scale=(radius,radius,(b-a).length*.55);o.rotation_mode='QUATERNION';o.rotation_quaternion=(b-a).to_track_quat('Z','Y');return parent(o,g)
def merge(g):
 for mat in list(bpy.data.materials):
  objects=[o for o in list(g.children) if o.type=='MESH' and mat in list(o.data.materials)]
  if not objects:continue
  bpy.ops.object.select_all(action='DESELECT')
  for o in objects:o.select_set(True)
  bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join()
weapon=group('Shotgun');pump=group('PumpSlide');support=group('SupportArm');grip=group('GripArm')
parent(cube('Steel receiver',(.19,-.19,-.56),(.085,.11,.26),steel,.012),weapon)
parent(cube('Shell ejection port',(.235,-.17,-.56),(.006,.045,.10),black,.003),weapon)
parent(barrel('Single firing barrel',(.19,-.157,-.91),.025,.54,steel),weapon)
parent(barrel('One muzzle bore',(.19,-.157,-1.184),.018,.007,rubber),weapon)
parent(barrel('Magazine tube (closed)',(.19,-.218,-.86),.018,.39,black),weapon)
parent(barrel('Closed magazine cap',(.19,-.218,-1.06),.021,.015,edge),weapon)
parent(cube('Stock',(.22,-.25,-.30),(.09,.12,.30),wood,.025),weapon)
parent(cube('Pistol grip',(.20,-.29,-.45),(.065,.15,.10),wood,.022),weapon)
# Rounded trigger guard, receiver fasteners and a brass shell in the carrier.
for z in [-.47,-.58,-.65]:
 o=barrel('Receiver fastener',(.237,-.19,z),.006,.004,edge);o.rotation_euler=(0,math.pi/2,0);parent(o,weapon)
for y in [-.31,-.34]:parent(cube('Trigger guard',(.19,y,-.52),(.054,.009,.10),black,.004),weapon)
parent(cube('Trigger guard front',(.19,-.325,-.57),(.054,.04,.009),black,.004),weapon)
parent(cube('Trigger blade',(.19,-.311,-.51),(.010,.033,.014),edge,.004),weapon)
parent(cube('Receiver raised rail',(.19,-.132,-.59),(.042,.012,.20),black,.004),weapon)
parent(cube('Rear sight' ,(.19,-.12,-.47),(.045,.022,.035),black,.004),weapon)
parent(cube('Front bead',(.19,-.125,-1.13),(.012,.015,.014),edge,.004),weapon)
parent(cube('Pump fore-end',(.19,-.23,-.85),(.095,.09,.24),wood,.026),pump)
for z in [-.76,-.80,-.84,-.88,-.92]:parent(cube('Pump grip rib',(.19,-.23,z),(.102,.085,.014),rubber,.006),pump)
# Connected forearms, wrists, palms and articulated fingers instead of mitten-like forms.
for name,g,a,b in [('Right',grip,(.37,-.61,-.10),(.22,-.33,-.43)),('Left',support,(-.25,-.60,-.12),(.135,-.29,-.83))]:
 mid=tuple((a[i]+b[i])*.5 for i in range(3))
 limb(name+' sleeve',a,mid,.061,fabric,g);limb(name+' forearm',mid,b,.044,skin,g)
 parent(ellipsoid(name+' wrist',b,(.030,.032,.043),skin),g)
parent(ellipsoid('Right palm',(.21,-.30,-.48),(.040,.047,.052),skin),grip)
for i in range(4):
 y=-.268-i*.021
 limb('Right proximal finger',(.237,y,-.51),(.212,y,-.555),.010,skin,grip)
 limb('Right fingertip',(.212,y,-.555),(.172,y,-.548),.009,skin,grip)
parent(ellipsoid('Right thumb',(.158,-.27,-.48),(.014,.030,.025),skin),grip)
parent(ellipsoid('Left palm',(.145,-.281,-.84),(.042,.030,.058),skin),support)
for i in range(4):
 z=-.765-i*.027
 limb('Left proximal finger',(.15,-.292,z),(.222,-.275,z),.010,skin,support)
 limb('Left fingertip',(.222,-.275,z),(.234,-.245,z),.009,skin,support)
for i in range(4):
 z=-.765-i*.027
 parent(ellipsoid('Left knuckle',(.227,-.27,z),(.012,.014,.012),skin),support)
 parent(ellipsoid('Left nail',(.236,-.244,z),(.003,.010,.006),nail),support)
parent(ellipsoid('Thenar muscle',(.17,-.27,-.49),(.025,.034,.035),skin),grip)
parent(ellipsoid('Left thumb' ,(.139,-.218,-.83),(.013,.020,.036),skin),support)
for g in [weapon,pump,support,grip]:merge(g)
path=Path(__file__).resolve().parents[1]/'assets/models/pump_shotgun.glb'
bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',export_animations=False)
# A matching open hand replaces the former harvesting glove as well.
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
hand=group('HarvestHand')
parent(ellipsoid('Anatomical palm',(0,0,0),(.044,.058,.023),skin),hand)
limb('Forearm',(0,-.31,.11),(0,-.075,.025),.041,skin,hand)
limb('Sleeve',(0,-.40,.16),(0,-.27,.10),.056,fabric,hand)
for i,length in enumerate([.081,.105,.098,.077]):
 x=-.034+i*.022
 limb('Finger proximal',(x,.039,0),(x,.039+length*.55,-.006),.0095,skin,hand)
 limb('Finger distal',(x,.039+length*.55,-.006),(x,.039+length,-.020),.008,skin,hand)
 parent(ellipsoid('Nail',(x,.036+length,-.027),(.006,.011,.002),nail),hand)
limb('Thumb',(-.035,-.025,0),(-.075,.016,-.009),.013,skin,hand)
merge(hand)
bpy.ops.export_scene.gltf(filepath=str(path.with_name('human_harvest.glb')),export_format='GLB',export_animations=False)
print('Original pump shotgun, arms and harvest hand exported')
