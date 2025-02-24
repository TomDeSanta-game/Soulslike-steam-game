extends BTAction

const TRANSITION_DURATION: float = 3.0
const POWER_UP_MULTIPLIER: float = 1.5

var transition_timer: float = 0.0
var is_transitioning: bool = false
var shader_material: ShaderMaterial

func _ready() -> void:
	# Load the power shader
	var shader = load("res://Shaders/Bosses/frost_power_shader.gdshader")
	shader_material = ShaderMaterial.new()
	shader_material.shader = shader

func _tick(delta: float) -> Status:
	if not is_transitioning:
		_start_transition()
		return RUNNING
		
	transition_timer += delta
	var progress = transition_timer / TRANSITION_DURATION
	
	# Update shader intensity
	shader_material.set_shader_parameter("power_intensity", progress)
	
	if transition_timer >= TRANSITION_DURATION:
		_complete_transition()
		return SUCCESS
		
	return RUNNING

func _start_transition() -> void:
	is_transitioning = true
	transition_timer = 0.0
	
	# Apply shader to sprite
	if agent.animated_sprite:
		agent.animated_sprite.material = shader_material
	
	# Play transition animation or effects
	if agent.has_method("play_transition_animation"):
		agent.play_transition_animation()

func _complete_transition() -> void:
	# Power up the boss
	if agent.has_method("power_up"):
		agent.power_up()
	else:
		# Default power-up implementation
		if "attack_damage" in agent:
			agent.attack_damage *= POWER_UP_MULTIPLIER
		if "attack_speed" in agent:
			agent.attack_speed *= POWER_UP_MULTIPLIER
	
	# Reset transition state
	is_transitioning = false
	transition_timer = 0.0

func reset() -> void:
	is_transitioning = false
	transition_timer = 0.0 