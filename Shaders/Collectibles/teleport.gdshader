shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float noise_scale = 30.0;
uniform float alpha_threshold = 0.5;
uniform float time : hint_range(0.0, 3.14159) = 0.0;

// Improved noise function for better randomness
vec2 random2(vec2 p) {
    return fract(sin(vec2(
        dot(p, vec2(127.1, 311.7)),
        dot(p, vec2(269.5, 183.3))
    )) * 43758.5453);
}

float voronoi(vec2 x) {
    vec2 n = floor(x);
    vec2 f = fract(x);

    float m = 8.0;
    for(int j = -1; j <= 1; j++) {
        for(int i = -1; i <= 1; i++) {
            vec2 g = vec2(float(i), float(j));
            vec2 o = random2(n + g);
            o = 0.5 + 0.5 * sin(time + 6.2831 * o);
            vec2 r = g + o - f;
            float d = dot(r, r);
            m = min(m, d);
        }
    }
    return sqrt(m);
}

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Create complex noise pattern
    vec2 noise_uv = UV * noise_scale;
    float noise = voronoi(noise_uv + vec2(time * 2.0));
    
    // Add swirl effect
    vec2 center = vec2(0.5, 0.5);
    vec2 tc = UV - center;
    float dist = length(tc);
    float angle = progress * 2.0 * 3.14159;
    float swirl = sin(dist * 10.0 - time * 4.0) * progress * 0.5;
    tc = mat2(
        vec2(cos(angle + swirl), -sin(angle + swirl)),
        vec2(sin(angle + swirl), cos(angle + swirl))
    ) * tc;
    vec2 swirled_uv = tc + center;
    
    // Calculate dissolve threshold with edge glow
    float threshold = progress;
    float edge_width = 0.15;
    
    // Create electric effect
    float electric = abs(sin(noise_uv.x * 10.0 + time * 5.0) * sin(noise_uv.y * 10.0 - time * 3.0));
    electric *= smoothstep(threshold - edge_width, threshold, noise);
    
    // Apply dissolve effect with multiple edges
    float alpha = step(threshold, noise);
    float edge = smoothstep(threshold - edge_width, threshold, noise) * 
                 smoothstep(threshold + edge_width, threshold, noise);
    
    // Create chromatic aberration
    float ca_amount = progress * 0.02;
    vec4 ca_color;
    ca_color.r = texture(TEXTURE, swirled_uv + vec2(ca_amount, 0.0)).r;
    ca_color.g = texture(TEXTURE, swirled_uv).g;
    ca_color.b = texture(TEXTURE, swirled_uv - vec2(ca_amount, 0.0)).b;
    ca_color.a = tex_color.a;
    
    // Combine all effects
    vec4 glow_color = mix(flash_color, vec4(0.5, 0.8, 1.0, 1.0), electric);
    vec4 final_color = mix(ca_color, glow_color, edge * 0.8);
    final_color += vec4(1.0, 0.5, 0.2, 1.0) * electric * 0.5;
    final_color.a = tex_color.a * (alpha + edge * 1.5);
    
    COLOR = final_color;
} 