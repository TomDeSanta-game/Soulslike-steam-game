shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 0.8, 0.0, 1.0);  // Golden outline
uniform float outline_width : hint_range(0, 10) = 1.0;
uniform float glow_intensity : hint_range(0, 2) = 0.5;
uniform vec4 glow_color : source_color = vec4(1.0, 0.9, 0.5, 0.5);    // Warm glow
uniform float time_offset : hint_range(0, 6.28) = 0.0;
uniform float pulse_speed : hint_range(0, 5) = 2.0;

void fragment() {
    vec4 current_color = texture(TEXTURE, UV);
    vec2 size = TEXTURE_PIXEL_SIZE;
    
    // Enhanced outline effect with double border
    float outline = 0.0;
    outline += texture(TEXTURE, UV + vec2(-size.x, 0) * outline_width).a;
    outline += texture(TEXTURE, UV + vec2(size.x, 0) * outline_width).a;
    outline += texture(TEXTURE, UV + vec2(0, -size.y) * outline_width).a;
    outline += texture(TEXTURE, UV + vec2(0, size.y) * outline_width).a;
    outline = min(outline, 1.0);
    
    float outer_outline = 0.0;
    float outer_width = outline_width * 2.0;
    outer_outline += texture(TEXTURE, UV + vec2(-size.x, 0) * outer_width).a;
    outer_outline += texture(TEXTURE, UV + vec2(size.x, 0) * outer_width).a;
    outer_outline += texture(TEXTURE, UV + vec2(0, -size.y) * outer_width).a;
    outer_outline += texture(TEXTURE, UV + vec2(0, size.y) * outer_width).a;
    outer_outline = min(outer_outline, 1.0);
    outer_outline -= outline;
    
    // Enhanced pulsing glow effect
    float base_glow = sin(TIME * pulse_speed + time_offset) * 0.5 + 0.5;
    float glow = base_glow * base_glow; // Square for more dramatic effect
    vec4 final_glow = glow_color * glow * glow_intensity;
    
    // Shimmering effect
    float shimmer = sin(UV.y * 20.0 + TIME * 2.0) * 0.5 + 0.5;
    shimmer *= sin(UV.x * 15.0 + TIME * 1.5) * 0.5 + 0.5;
    
    // Combine effects
    vec4 final_color = current_color;
    if (outer_outline > 0.0) {
        final_color = mix(final_color, outline_color * 0.5, outer_outline);
    }
    if (outline > 0.0) {
        final_color = mix(final_color, outline_color, outline);
    }
    
    // Add shimmer and glow
    final_color = mix(final_color, final_color + final_glow, current_color.a * glow);
    final_color = mix(final_color, final_color + outline_color, shimmer * 0.2 * current_color.a);
    
    COLOR = final_color;
} 