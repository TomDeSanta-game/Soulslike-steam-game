shader_type canvas_item;

// Core colors
uniform vec4 core_color : source_color = vec4(1.0, 0.2, 0.5, 1.0);
uniform vec4 orbit_color : source_color = vec4(0.2, 0.5, 1.0, 1.0);
uniform vec4 particle_color : source_color = vec4(1.0, 0.8, 0.2, 1.0);

// Orbital system
uniform float orbit_count : hint_range(1.0, 8.0) = 3.0;
uniform float orbit_speed : hint_range(-2.0, 2.0) = 0.8;
uniform float particle_count : hint_range(3.0, 12.0) = 6.0;
uniform float particle_size : hint_range(0.01, 0.1) = 0.05;

// Energy field
uniform float energy_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float energy_flow_speed : hint_range(0.0, 3.0) = 1.0;
uniform float tendril_count : hint_range(2.0, 8.0) = 4.0;
uniform float tendril_twist : hint_range(0.0, 6.28) = 3.14;

// Animation and effects
uniform float pulse_frequency : hint_range(0.0, 5.0) = 2.0;
uniform float core_size : hint_range(0.0, 0.3) = 0.15;
uniform float glow_radius : hint_range(0.3, 1.0) = 0.6;

// Hash function for particle positions
float hash(vec2 p) {
    float h = dot(p, vec2(127.1, 311.7));
    return fract(sin(h) * 43758.5453123);
}

// Smooth noise function
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float n = mix(
        mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
        f.y
    );
    
    return n * 2.0 - 1.0;
}

// Energy field function
float energy_field(vec2 uv, float time) {
    float e = 0.0;
    for(float i = 1.0; i <= 3.0; i++) {
        float phase = time * energy_flow_speed * (0.5 + i * 0.2);
        vec2 offset = vec2(
            cos(phase + uv.y * tendril_twist * i),
            sin(phase + uv.x * tendril_twist * i)
        );
        e += noise(uv * (i * 2.0) + offset) / i;
    }
    return e;
}

// Orbital particle function
float orbital_particles(vec2 uv, float time) {
    float particles = 0.0;
    
    for(float orbit = 1.0; orbit <= orbit_count; orbit++) {
        float orbit_radius = orbit * 0.15;
        float orbit_angle = time * orbit_speed * (1.0 + orbit * 0.2);
        
        for(float i = 0.0; i < particle_count; i++) {
            float particle_angle = (i / particle_count) * 6.28 + orbit_angle;
            vec2 particle_pos = vec2(
                cos(particle_angle) * orbit_radius,
                sin(particle_angle) * orbit_radius
            );
            
            float particle = length(uv - particle_pos) - particle_size;
            particles = max(particles, smoothstep(0.01, 0.0, particle));
        }
    }
    
    return particles;
}

// Core glow function
float core_glow(float dist, float time) {
    float pulse = sin(time * pulse_frequency) * 0.5 + 0.5;
    float core = smoothstep(core_size + 0.1, core_size - 0.1, dist);
    float glow = smoothstep(glow_radius, core_size, dist);
    return core + glow * pulse;
}

void fragment() {
    // Setup coordinates
    vec2 uv = UV - vec2(0.5);
    float dist = length(uv);
    float time = TIME;
    
    // Generate base effects
    float energy = energy_field(uv, time) * energy_intensity;
    float particles = orbital_particles(uv, time);
    float core = core_glow(dist, time);
    
    // Create tendrils
    float tendrils = 0.0;
    for(float i = 0.0; i < tendril_count; i++) {
        float angle = i * (6.28 / tendril_count) + time * energy_flow_speed;
        vec2 dir = vec2(cos(angle), sin(angle));
        float d = abs(dot(normalize(uv), dir));
        tendrils += smoothstep(0.9, 1.0, d) * smoothstep(glow_radius, 0.0, dist);
    }
    
    // Color composition
    vec4 base_color = texture(TEXTURE, UV);
    vec4 energy_color = mix(core_color, orbit_color, energy * 0.5 + 0.5);
    vec4 final_color = base_color;
    
    // Add core
    final_color += core_color * core;
    
    // Add energy field
    final_color += energy_color * energy * (1.0 - core) * 0.5;
    
    // Add particles
    final_color += particle_color * particles;
    
    // Add tendrils
    final_color += orbit_color * tendrils * 0.5;
    
    // Apply glow falloff
    final_color *= smoothstep(glow_radius + 0.2, 0.0, dist);
    
    // Preserve original alpha
    final_color.a = base_color.a;
    
    COLOR = final_color;
} 