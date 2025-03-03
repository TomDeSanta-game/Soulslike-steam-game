shader_type canvas_item;

uniform vec4 flash_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float flash_modifier : hint_range(0.0, 1.0) = 0.0;
uniform vec4 base_color_shift : source_color = vec4(0.3, 0.3, 0.35, 1.0);
uniform vec4 accent_color : source_color = vec4(0.7, 0.1, 0.1, 1.0);

void fragment() {
    // Get the original texture color
    vec4 original_color = texture(TEXTURE, UV);
    
    // Convert to grayscale
    float gray = dot(original_color.rgb, vec3(0.299, 0.587, 0.114));
    
    // Create gray base with red accent for brighter areas
    vec3 new_color = mix(base_color_shift.rgb * gray, accent_color.rgb, step(0.7, gray));
    
    // Apply flash effect when taking damage
    vec3 final_color = mix(new_color, flash_color.rgb, flash_modifier);
    
    // Preserve alpha
    COLOR = vec4(final_color, original_color.a);
} 