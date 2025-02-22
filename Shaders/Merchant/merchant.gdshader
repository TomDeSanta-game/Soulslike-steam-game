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
    
    // Outline effect
    float outline = 0.0;
    outline += texture(TEXTURE, UV + vec2(-size.x, 0) * outline_width).a;
    outline += texture(TEXTURE, UV + vec2(size.x, 0) * outline_width).a;
    outline += texture(TEXTURE, UV + vec2(0, -size.y) * outline_width).a;
    outline += texture(TEXTURE, UV + vec2(0, size.y) * outline_width).a;
    outline = min(outline, 1.0);
    outline -= current_color.a;
    
    // Pulsing glow effect
    float glow = sin(TIME * pulse_speed + time_offset) * 0.5 + 0.5;
    vec4 final_glow = glow_color * glow * glow_intensity;
    
    // Combine effects
    vec4 final_color = current_color;
    if (outline > 0.0) {
        final_color = outline_color;
    }
    final_color = mix(final_color, final_color + final_glow, current_color.a * glow);
    
    COLOR = final_color;
} 