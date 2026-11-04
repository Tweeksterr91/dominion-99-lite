shader_type sky;
uniform vec4 zenith : source_color = vec4(.08,.11,.17,1.);
uniform vec4 horizon : source_color = vec4(.22,.25,.30,1.);
uniform float night_amount : hint_range(0.,1.) = 1.;
uniform float cloud_cover : hint_range(0.,1.) = .65;
uniform float cloud_time = 0.;
float hash(float p){return fract(sin(p*127.1)*43758.5453);}
float hash3(vec3 p){p=fract(p*.1031);p+=dot(p,p.yzx+33.33);return fract((p.x+p.y)*p.z);}
float noise3(vec3 p){
 vec3 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);
 return mix(mix(mix(hash3(i),hash3(i+vec3(1,0,0)),f.x),mix(hash3(i+vec3(0,1,0)),hash3(i+vec3(1,1,0)),f.x),f.y),
 mix(mix(hash3(i+vec3(0,0,1)),hash3(i+vec3(1,0,1)),f.x),mix(hash3(i+vec3(0,1,1)),hash3(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void sky(){
 float altitude=EYEDIR.y;
 vec3 color=mix(horizon.rgb,zenith.rgb,pow(clamp(altitude,0.,1.),.55));
 float azimuth=(atan(EYEDIR.z,EYEDIR.x)+3.14159265)/6.2831853;
 // Sparse, feathered pinpricks, muted under cloud and near the city haze.
 vec2 grid=vec2(azimuth*860.,altitude*150.);vec2 cell=floor(grid);
 float seed=hash(cell.x+cell.y*912.7);
 vec2 point=vec2(hash(seed*871.),hash(seed*1193.));
 float star=exp2(-dot(fract(grid)-point,fract(grid)-point)*75.)*step(.994,seed);
 color+=vec3(.70,.79,.94)*star*.40*night_amount*smoothstep(.12,.45,altitude);
 vec3 moon_dir=normalize(vec3(-.42,.48,-.77));
 float alignment=dot(EYEDIR,moon_dir);
 float disc=smoothstep(cos(.0155),cos(.014),alignment);
 float crater=.84+.16*noise3(EYEDIR*480.);
 color+=vec3(.66,.73,.84)*(disc*crater*.70+pow(max(alignment,0.),1200.)*.025)*(.25+.75*night_amount);
 // Four samples through a 3D density field: shallow, lit sky volume rather than flat cloud cards.
 if(altitude>.025){
  float transmittance=1.;vec3 cloud=vec3(0.);
  for(int i=0;i<4;i++){
   float layer=float(i)/3.;
   vec3 p=EYEDIR*((1.8+layer*.65)/max(altitude,.12));p.xz+=vec2(cloud_time*.006,cloud_time*.002);
   float density=noise3(p*.90)*.72+noise3(p*2.15+11.)*.28;
   density=smoothstep(.75-cloud_cover*.36,.98-cloud_cover*.36,density)*.68;
   density*=smoothstep(.025,.16,altitude);
   vec3 lit=mix(zenith.rgb*.52,horizon.rgb*.85+vec3(.035,.040,.055),layer*.65+.2);
   cloud+=lit*density*transmittance;transmittance*=1.-density;
  }
  color=color*transmittance+cloud;
 }
 float block=azimuth*110.;float id=floor(block);float x=fract(block);
 float height=.025+hash(id)*.10;
 height-=x<.18||x>.82?.020:0.;
 if(hash(id+9.)>.84&&x>.43&&x<.57)height+=.04;
 if(altitude<height&&altitude>-.10&&x>.025&&x<.975){
  color=mix(vec3(.025,.035,.047),horizon.rgb,.13);
  float row=floor(altitude*460.);float col=floor(x*7.);
  if(fract(altitude*460.)>.4&&fract(x*7.)>.4&&hash(id*90.+row*7.+col)>.79)
   color+=vec3(.22,.14,.055)*.45;
 }
 if(altitude<-.05)color=mix(color,vec3(.025,.035,.04),clamp((-altitude-.05)*2.,0.,1.));
 COLOR=color;
}
