shader_type sky;
uniform vec4 zenith : source_color = vec4(.08,.11,.17,1.);
uniform vec4 horizon : source_color = vec4(.22,.25,.30,1.);
float hash(float p){return fract(sin(p*127.1)*43758.5453);}
void sky(){
 float altitude=EYEDIR.y;
 vec3 color=mix(horizon.rgb,zenith.rgb,pow(clamp(altitude,0.,1.),.55));
 float azimuth=(atan(EYEDIR.z,EYEDIR.x)+3.14159265)/6.2831853;
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
