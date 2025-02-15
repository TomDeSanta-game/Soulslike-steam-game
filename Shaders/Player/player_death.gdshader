shader_type canvas_item;

uniform float fade_progress : hint_range(0.0, 1.0) = 0.0; // Controls the fade progress (0.0 = fully visible, 1.0 = fully faded)

void fragment() {
    // Get the original texture color
    vec4 original_color = texture(TEXTURE, UV);

    // Reduce the alpha based on fade_progress
    float alpha = original_color.a * (1.0 - fade_progress);

    // Output the final color with reduced alpha
    COLOR = vec4(original_color.rgb, alpha);
}
