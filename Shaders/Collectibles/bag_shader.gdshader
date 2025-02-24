shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 0.92, 0.75, 0.4);
uniform vec4 inner_glow_color : source_color = vec4(1.0, 0.8, 0.4, 0.6);
uniform float pulse_speed : hint_range(0.1, 5.0) = 2.0;
uniform float sparkle_speed : hint_range(0.1, 5.0) = 3.0;
uniform float edge_thickness : hint_range(0.0, 2.0) = 1.0;
uniform float glow_intensity : hint_range(0.1, 2.0) = 1.2;
uniform float inner_glow_intensity : hint_range(0.1, 2.0) = 0.8;
uniform float sparkle_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float sparkle_density : hint_range(1.0, 30.0) = 15.0;

// Hash function for pseudo-random numbers
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec4 texture_color = texture(TEXTURE, UV);
    
    // Calculate main pulse effect
    float pulse = (sin(TIME * pulse_speed) * 0.5 + 0.5) * 0.3 + 0.7;
    
    // Edge detection for outer glow
    vec2 size = TEXTURE_PIXEL_SIZE * edge_thickness;
    float alpha = texture_color.a;
    alpha += texture(TEXTURE, UV + vec2(0.0, -size.y)).a;
    alpha += texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
    alpha += texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
    alpha += texture(TEXTURE, UV + vec2(0.0, size.y)).a;
    
    // Create edge glow
    float edge_glow = min(1.0, alpha) - texture_color.a;
    
    // Calculate inner glow
    float center_distance = length(UV - vec2(0.5));
    float inner_glow = 1.0 - smoothstep(0.0, 0.5, center_distance);
    inner_glow *= inner_glow_intensity * pulse;
    
    // Generate sparkles
    vec2 sparkle_uv = UV * sparkle_density;
    float sparkle_time = TIME * sparkle_speed;
    float sparkle = random(floor(sparkle_uv) + floor(sparkle_time));
    sparkle = pow(sparkle, 20.0) * sparkle_intensity * pulse;
    
    // Combine all effects
    vec4 final_color = texture_color;
    
    // Apply outer glow
    final_color.rgb = mix(final_color.rgb, glow_color.rgb, edge_glow * glow_intensity * pulse);
    
    // Apply inner glow
    final_color.rgb = mix(final_color.rgb, inner_glow_color.rgb, inner_glow * texture_color.a);
    
    // Add sparkles
    final_color.rgb += sparkle * inner_glow_color.rgb * texture_color.a;
    
    // Set final alpha
    final_color.a = texture_color.a + edge_glow * glow_color.a * pulse;
    
    COLOR = final_color;
} 