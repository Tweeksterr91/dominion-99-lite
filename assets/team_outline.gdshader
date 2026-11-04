shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled;
uniform vec4 team_color : source_color = vec4(0.15,0.55,1.0,1.0);
uniform float width = 0.022;
void vertex() { VERTEX += NORMAL * width; }
void fragment() { ALBEDO = team_color.rgb; }
