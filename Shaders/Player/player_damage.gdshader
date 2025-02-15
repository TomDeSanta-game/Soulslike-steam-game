shader_type canvas_item;

uniform float effect_progress : hint_range(0.0, 1.0) = 0.0; // Controls the progress of the effect
uniform vec4 red_color = vec4(1.0, 0.0, 0.0, 1.0); // Red color
uniform vec4 outline_color = vec4(1.0, 1.0, 1.0, 1.0); // White outline color
uniform float outline_thickness : hint_range(0.0, 10.0) = 2.0; // Thickness of the outline

void fragment() {
    // Get the original texture color and alpha
    vec4 original_color = texture(TEXTURE, UV);
    float alpha = original_color.a; // Use the texture's alpha channel

    // Only apply the effect to visible pixels (non-transparent)
    if (alpha > 0.0) {
        // Calculate the effect phases
        float red_phase = smoothstep(0.0, 0.3, effect_progress); // Red phase (0.0 to 0.3)
        float outline_phase = smoothstep(0.3, 0.7, effect_progress); // Outline phase (0.3 to 0.7)
        float return_phase = smoothstep(0.7, 1.0, effect_progress); // Return to normal phase (0.7 to 1.0)

        // Apply the red color
        vec4 red_tint = mix(original_color, red_color, red_phase);

        // Apply the white outline
        vec4 outline_tint = mix(red_tint, outline_color, outline_phase);

        // Calculate the outline effect
        vec2 pixel_size = vec2(outline_thickness) / SCREEN_PIXEL_SIZE;
        vec4 outline = vec4(0.0);
        for (float x = -1.0; x <= 1.0; x += 1.0) {
            for (float y = -1.0; y <= 1.0; y += 1.0) {
                outline += texture(TEXTURE, UV + vec2(x, y) * pixel_size);
            }
        }
        outline /= 9.0; // Average the outline samples
        outline = mix(outline_tint, outline_color, outline_phase);

        // Blend the outline with the red tint
        vec4 final_color = mix(outline_tint, outline, outline_phase);

        // Return to normal
        final_color = mix(final_color, original_color, return_phase);

        COLOR = final_color;
    } else {
        // Discard fully transparent pixels
        COLOR = vec4(0.0);
    }
}
