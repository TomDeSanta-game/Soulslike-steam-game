shader_type canvas_item;

uniform float time_elapsed : hint_range(0.0, 10.0) = 0.0;
uniform float base_visible_duration : hint_range(0.1, 1.0) = 0.2;  // Base duration for visible state
uniform float base_invisible_duration : hint_range(0.1, 1.0) = 0.1;  // Base duration for invisible state
uniform float duration_increase_rate : hint_range(0.001, 0.01) = 0.001;  // How much to increase duration each cycle

void fragment() {
    vec4 texture_color = texture(TEXTURE, UV);
    
    // Calculate the current cycle duration
    float cycle_duration = base_visible_duration + base_invisible_duration + 
                         (time_elapsed * duration_increase_rate);
    
    // Calculate the current phase within the cycle
    float phase = mod(TIME, cycle_duration);
    
    // Determine if we should be visible or invisible
    float alpha = phase < (base_invisible_duration + (time_elapsed * duration_increase_rate)) ? 0.2 : 1.0;
    
    // Output the color with modified alpha
    COLOR = vec4(texture_color.rgb, texture_color.a * alpha);
} 