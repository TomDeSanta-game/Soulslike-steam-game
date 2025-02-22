shader_type canvas_item;

// Core colors
uniform vec4 inner_light : source_color = vec4(0.4, 0.7, 1.0, 1.0);      // Bright blue core
uniform vec4 outer_light : source_color = vec4(0.2, 0.4, 1.0, 1.0);      // Deep blue aura
uniform vec4 void_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);       // Pure black
uniform vec4 void_accent : source_color = vec4(0.2, 0.2, 0.2, 1.0);      // Dark gray

// Animation timing
uniform float cycle_speed : hint_range(0.1, 2.0) = 0.35;                 // Slowed down for longer phases
uniform float void_duration : hint_range(0.1, 2.0) = 1.0;
uniform float glow_duration : hint_range(0.1, 5.0) = 2.0;

// Effect parameters
uniform float energy_rings : hint_range(2.0, 8.0) = 4.0;
uniform float light_intensity : hint_range(0.5, 3.0) = 1.5;

// Void phase parameters
uniform float void_ring_count : hint_range(1.0, 8.0) = 3.0;
uniform float void_ring_speed : hint_range(0.1, 2.0) = 0.5;

float energy_field(vec2 uv, float time, float phase) {
    float energy = 0.0;
    float dist = length(uv);
    
    // Simple expanding rings
    for(float i = 1.0; i <= energy_rings; i++) {
        float ring = length(uv) - (time * 0.2 * i);
        ring = fract(ring * 2.0) * phase;
        energy += smoothstep(0.5, 0.1, abs(ring - 0.5));
    }
    
    // Add smooth falloff from center
    energy *= smoothstep(1.0, 0.0, dist);
    
    return energy;
}

float void_rings(vec2 uv, float time) {
    float rings = 0.0;
    float dist = length(uv);
    
    for(float i = 1.0; i <= void_ring_count; i++) {
        float ring_pos = fract(dist * 2.0 - time * void_ring_speed * i);
        rings += smoothstep(0.1, 0.0, abs(ring_pos - 0.5)) * (1.0 - dist);
    }
    
    return rings;
}

void fragment() {
    // Setup coordinates
    vec2 uv = UV * 2.0 - 1.0;
    float time = TIME * cycle_speed;
    
    // Calculate phase timing with longer glow duration
    float cycle = fract(time);
    float total_duration = glow_duration + void_duration;
    float normalized_time = cycle * total_duration;
    float void_phase = smoothstep(glow_duration, glow_duration + 0.2, normalized_time) * 
                      smoothstep(total_duration, total_duration - 0.2, normalized_time);
    float light_phase = 1.0 - void_phase;
    
    // Get base texture
    vec4 base_color = texture(TEXTURE, UV);
    vec4 final_color = base_color;
    
    // Light phase effects
    if (light_phase > 0.0) {
        float energy = energy_field(uv, time, light_phase);
        
        // Simple radial glow
        float dist = length(uv);
        float center_glow = smoothstep(1.0, 0.0, dist) * light_phase;
        
        // Combine center glow with energy rings
        float light_pattern = energy * 0.6 + center_glow * 0.4;
        vec4 light_color = mix(outer_light, inner_light, light_pattern);
        final_color += light_color * light_pattern * light_intensity * light_phase;
    }
    
    // Void phase effects
    if (void_phase > 0.0) {
        float rings = void_rings(uv, time);
        vec4 void_effect_color = mix(void_color, void_accent, rings * 0.5);
        final_color = mix(final_color, void_effect_color, void_phase);
    }
    
    // Preserve original alpha
    final_color.a = base_color.a;
    
    COLOR = final_color;
} 