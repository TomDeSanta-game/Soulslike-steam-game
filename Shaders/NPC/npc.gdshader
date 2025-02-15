shader_type canvas_item;

uniform float damage_effect : hint_range(0.0, 1.0);

void fragment() {
    // Get the original texture color
    vec4 tex_color = texture(TEXTURE, UV);
    
    // If damage_effect is active, blend the color with red
    if (damage_effect > 0.0) {
        tex_color.rgb = mix(tex_color.rgb, vec3(1.0, 0.0, 0.0), damage_effect);
    }
    
    // Output the final color
    COLOR = tex_color;
}
