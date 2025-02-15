shader_type canvas_item;

uniform float pulsate_speed: hint_range(0.1, 5.0) = 1.0; // Speed of the pulsation
uniform float pulsate_intensity: hint_range(0.0, 1.0) = 0.5; // Intensity of the pulsation
uniform float base_alpha: hint_range(0.0, 1.0) = 0.7; // Base transparency level

void fragment() {
    // Get the original color of the pixel
    vec4 original_color = texture(TEXTURE, UV);

    // Discard fully transparent pixels
    if (original_color.a == 0.0) {
        discard;
    }

    // Convert the color to grayscale
    float grayscale = (original_color.r + original_color.g + original_color.b) / 3.0;

    // Apply grayscale to the original color
    vec3 gray_color = vec3(grayscale);

    // Calculate the pulsating alpha using a sine function
    float alpha = base_alpha + (0.3 * sin(TIME * pulsate_speed)) * pulsate_intensity;

    // Combine grayscale color with transparency
    vec4 ghost_color = vec4(gray_color, alpha);

    // Output the final color
    COLOR = ghost_color;
}
