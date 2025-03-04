shader_type canvas_item;

uniform vec4 flash_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float flash_modifier : hint_range(0.0, 1.0) = 0.0;
uniform vec4 base_color_shift : source_color = vec4(0.3, 0.3, 0.35, 1.0);
uniform vec4 accent_color : source_color = vec4(0.7, 0.1, 0.1, 1.0);

void fragment() {
    vec4 texture_color = texture(TEXTURE, UV);
    vec4 shifted_color = mix(texture_color, texture_color * base_color_shift, 0.5);
    vec4 final_color = mix(shifted_color, accent_color, flash_modifier);
    
    // Add flash effect
    final_color = mix(final_color, flash_color, flash_modifier);
    
    COLOR = final_color;
} 