shader_type canvas_item;

uniform vec4 frost_color : source_color = vec4(0.7, 0.9, 1.0, 1.0);
uniform float frost_mix : hint_range(0.0, 1.0) = 0.3;
uniform float frost_scale : hint_range(0.0, 10.0) = 1.0;
uniform float time_scale : hint_range(0.0, 2.0) = 0.5;

float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec4 texture_color = texture(TEXTURE, UV);
    
    // Create frost pattern
    vec2 scaled_uv = UV * frost_scale;
    scaled_uv.y += TIME * time_scale;
    float frost_pattern = random(scaled_uv);
    
    // Mix original color with frost effect
    vec4 final_color = mix(texture_color, frost_color, frost_mix * frost_pattern);
    
    COLOR = final_color;
} 