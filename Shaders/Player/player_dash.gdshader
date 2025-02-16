shader_type canvas_item;

uniform float dash_intensity : hint_range(0.0, 1.0) = 0.5;
uniform vec4 dash_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float dash_speed : hint_range(0.0, 10.0) = 5.0;
uniform float dash_width : hint_range(0.0, 1.0) = 0.2;

void fragment() {
    // Get the current texture color
    vec4 current_color = texture(TEXTURE, UV);
    
    // Calculate the wave effect
    float wave = sin(UV.x * 10.0 + TIME * dash_speed) * 0.5 + 0.5;
    
    // Create the dash trail effect
    float dash_trail = smoothstep(1.0 - dash_width, 1.0, wave) * dash_intensity;
    
    // Mix the original color with the dash effect
    vec4 final_color = mix(current_color, dash_color, dash_trail * (1.0 - UV.x));
    
    // Apply transparency based on the original alpha
    COLOR = vec4(final_color.rgb, final_color.a * current_color.a);
}
