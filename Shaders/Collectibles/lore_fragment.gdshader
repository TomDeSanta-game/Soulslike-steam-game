shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 0.9, 0.7, 1.0);
uniform float glow_intensity : hint_range(0.0, 2.0) = 0.5;
uniform float wave_speed : hint_range(0.0, 5.0) = 1.0;
uniform float wave_amplitude : hint_range(0.0, 0.1) = 0.005;
uniform sampler2D noise_texture;

void fragment() {
    // Sample the base texture
    vec4 base_color = texture(TEXTURE, UV);
    
    // Create a wavy effect
    float wave = sin(TIME * wave_speed + UV.y * 10.0) * wave_amplitude;
    vec2 wave_uv = UV + vec2(wave, 0.0);
    
    // Sample the texture with the wave effect
    vec4 final_color = texture(TEXTURE, wave_uv);
    
    // Add noise texture for parchment-like effect
    vec4 noise = texture(noise_texture, UV * 2.0 + TIME * 0.1);
    
    // Create a pulsing glow effect
    float pulse = (sin(TIME) * 0.5 + 0.5) * 0.3 + 0.7;
    
    // Mix the base color with the glow
    vec4 glow = glow_color * glow_intensity * pulse;
    final_color = mix(final_color, glow, 0.3);
    
    // Apply noise
    final_color = mix(final_color, noise, 0.1);
    
    // Preserve original alpha
    final_color.a = base_color.a;
    
    COLOR = final_color;
} 