shader_type canvas_item;

// Normal map texture
uniform sampler2D normal_texture : hint_normal;

void fragment() {
    // Get the color from the sprite texture
    vec4 color = texture(TEXTURE, UV);
    
    // Only process pixels that aren't transparent
    if (color.a > 0.0) {
        // Get the normal from the normal map
        vec3 normal = texture(normal_texture, UV).rgb;
        
        // Convert from [0,1] to [-1,1] range
        normal = normal * 2.0 - 1.0;
        
        // Apply the normal to the fragment
        NORMAL = normal;
    }
    
    // Output the original color
    COLOR = color;
} 