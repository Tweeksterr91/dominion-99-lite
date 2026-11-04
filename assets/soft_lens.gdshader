shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, depth_draw_never, depth_test_disabled;
uniform sampler2D screen_image : hint_screen_texture, repeat_disable, filter_linear;
uniform sampler2D scene_depth : hint_depth_texture, repeat_disable, filter_nearest;
uniform bool dof_enabled = true;
uniform bool bloom_enabled = true;
uniform bool chromatic_enabled = true;
uniform vec2 motion_pixels = vec2(0.);
uniform float focus_distance = 18.;
uniform float strength = 1.;
float distance_at(vec2 uv,mat4 inverse_projection){
 float depth=texture(scene_depth,uv).r;
 #if CURRENT_RENDERER == RENDERER_COMPATIBILITY
 vec3 ndc=vec3(uv,depth)*2.-1.;
 #else
 vec3 ndc=vec3(uv*2.-1.,depth);
 #endif
 vec4 p=inverse_projection*vec4(ndc,1.);
 return clamp(-p.z/max(abs(p.w),.00001),0.,300.);
}
vec3 bright(vec3 c){return c*smoothstep(.53,.90,max(c.r,max(c.g,c.b)));}
void vertex(){POSITION=vec4(VERTEX.xy,1.,1.);}
void fragment(){
 vec2 uv=SCREEN_UV;vec2 pixel=1./VIEWPORT_SIZE;
 vec3 original=texture(screen_image,uv).rgb;
 float distance=distance_at(uv,INV_PROJECTION_MATRIX);
 // Focus follows the crosshair's world hit. Near weapon geometry and aim center stay clear.
 float defocus=smoothstep(14.,100.,abs(distance-focus_distance))*smoothstep(3.,8.,distance);
 defocus*=smoothstep(.08,.38,length((uv-.5)*vec2(VIEWPORT_SIZE.x/VIEWPORT_SIZE.y,1.)));
 float radius=dof_enabled?defocus*2.2:0.;
 vec3 soft=original;vec3 glow=bright(original);
 for(int i=0;i<8;i++){
  float a=float(i)*.78539816;vec2 direction=vec2(cos(a),sin(a));
  vec2 offset=direction*radius+motion_pixels*(float(i)/7.-.5);
  // Reject foreground/background crossings so distant blur cannot smear nearby silhouettes.
  vec2 at=clamp(uv+offset*pixel,vec2(0.001),vec2(.999));
  float other=distance_at(at,INV_PROJECTION_MATRIX);
  float keep=1.-smoothstep(2.,8.,abs(other-distance));
  soft+=mix(original,texture(screen_image,at).rgb,keep);
  if(bloom_enabled)glow+=bright(texture(screen_image,clamp(uv+direction*pixel*5.,vec2(.001),vec2(.999))).rgb);
 }
 vec3 result=soft/9.;
 if(chromatic_enabled){
  vec2 edge=uv-.5;vec2 offset=sign(edge)*pixel;
  float separation=clamp(length(edge)*dot(edge,edge)*2.2,0.,.6);
  result.r+=(texture(screen_image,clamp(uv+offset,vec2(.001),vec2(.999))).r-original.r)*separation;
  result.b+=(texture(screen_image,clamp(uv-offset,vec2(.001),vec2(.999))).b-original.b)*separation;
 }
 if(bloom_enabled)result+=glow/9.*.10;
 ALBEDO=mix(original,result,strength);ALPHA=1.;
}
