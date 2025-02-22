shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 0.8, 0.4, 1.0);  // Warmer golden color
uniform float glow_intensity : hint_range(0.0, 3.0) = 2.0;
uniform float pulse_speed : hint_range(0.0, 5.0) = 3.0;
uniform float ray_speed : hint_range(0.0, 5.0) = 2.0;
uniform float ray_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float distortion_strength : hint_range(0.0, 0.1) = 0.02;

void fragment() {
    // Get the base texture color
    vec2 distorted_uv = UV;
    
    // Add wavy distortion
    distorted_uv.x += sin(UV.y * 10.0 + TIME * 2.0) * distortion_strength;
    distorted_uv.y += cos(UV.x * 10.0 + TIME * 2.0) * distortion_strength;
    vec4 base_color = texture(TEXTURE, distorted_uv);
    
    // Calculate distance from center
    vec2 center = vec2(0.5, 0.5);
    float dist = length(UV - center);
    
    // Create strong pulsing glow
    float pulse = (sin(TIME * pulse_speed) + 1.0) * 0.5;
    float glow = (1.0 - dist * 2.0) * pulse * glow_intensity;
    
    // Create rotating light rays
    float angle = atan(UV.y - 0.5, UV.x - 0.5);
    float rays = abs(sin(angle * 8.0 + TIME * ray_speed)) * ray_intensity;
    rays *= smoothstep(1.0, 0.0, dist * 2.0);
    
    // Edge highlight
    float edge = smoothstep(0.5, 0.4, dist) * smoothstep(0.0, 0.1, dist);
    
    // Combine effects
    vec4 final_color = base_color;
    final_color.rgb += glow_color.rgb * glow;  // Add pulsing glow
    final_color.rgb += glow_color.rgb * rays;  // Add rays
    final_color.rgb += glow_color.rgb * edge * pulse;  // Add edge highlight
    final_color.a = base_color.a;  // Preserve original alpha
    
    COLOR = final_color;
} 