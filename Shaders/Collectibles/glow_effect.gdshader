shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float glow_intensity : hint_range(0.0, 3.0) = 1.0;
uniform float glow_scale : hint_range(0.0, 4.0) = 1.0;
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.0;
uniform float outer_radius : hint_range(0.0, 2.0) = 0.4;
uniform float inner_radius : hint_range(0.0, 2.0) = 0.1;
uniform float light_intensity : hint_range(0.0, 2.0) = 0.5;

void fragment() {
    vec4 texture_color = texture(TEXTURE, UV);
    
    // Create pulsing effect
    float pulse = (sin(TIME * pulse_speed) + 1.0) * 0.5;
    
    // Calculate glow
    vec2 size = TEXTURE_PIXEL_SIZE * glow_scale;
    float glow = 0.0;
    
    // Sample surrounding pixels for glow
    glow += texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
    glow += texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
    glow += texture(TEXTURE, UV + vec2(0.0, -size.y)).a;
    glow += texture(TEXTURE, UV + vec2(0.0, size.y)).a;
    
    glow = glow * 0.25; // Average the samples
    glow = glow * glow_intensity * pulse; // Apply intensity and pulse
    
    // Add surrounding light effect
    vec2 center = vec2(0.5, 0.5);
    float dist = length(UV - center);
    
    // Create soft light falloff
    float light_factor = smoothstep(outer_radius, inner_radius, dist);
    light_factor *= light_intensity * pulse;
    
    // Mix original color with glow and light
    vec4 final_glow = glow_color * glow;
    vec4 light_color = glow_color * light_factor;
    
    COLOR = mix(texture_color, final_glow, glow * glow_color.a);
    COLOR = mix(COLOR, light_color, light_factor * 0.5);
    COLOR.a = max(texture_color.a + glow * glow_color.a, light_factor * 0.3);
}

