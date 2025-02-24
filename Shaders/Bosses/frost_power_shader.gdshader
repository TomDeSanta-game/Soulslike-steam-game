shader_type canvas_item;

uniform vec4 frost_color : source_color = vec4(0.5, 0.8, 1.0, 1.0);
uniform vec4 power_color : source_color = vec4(0.0, 0.5, 1.0, 1.0);
uniform float frost_mix : hint_range(0.0, 1.0) = 0.5;
uniform float frost_scale : hint_range(0.0, 10.0) = 2.0;
uniform float time_scale : hint_range(0.0, 2.0) = 1.0;
uniform float power_intensity : hint_range(0.0, 1.0) = 0.0;

float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec4 texture_color = texture(TEXTURE, UV);
    
    // Create frost pattern
    vec2 scaled_uv = UV * frost_scale;
    scaled_uv.y += TIME * time_scale;
    float frost_pattern = random(scaled_uv);
    
    // Create power-up effect
    float power_pattern = sin(TIME * 3.0 + UV.y * 10.0) * 0.5 + 0.5;
    
    // Mix colors based on power state
    vec4 frost_effect = mix(frost_color, power_color, power_pattern * power_intensity);
    vec4 final_color = mix(texture_color, frost_effect, frost_mix * frost_pattern);
    
    // Add pulsing glow during transition
    final_color.rgb += power_color.rgb * power_intensity * power_pattern * 0.3;
    
    COLOR = final_color;
} 