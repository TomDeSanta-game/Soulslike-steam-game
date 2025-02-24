extends BTAction

@export var target_var: StringName = &"target"
@export var attack_range: float = 60.0
@export var frost_damage: float = 15.0
@export var attack_cooldown: float = 1.5
@export var frost_effect_duration: float = 3.0

var _current_cooldown: float = 0.0

func _tick(delta: float) -> Status:
	if _current_cooldown > 0:
		_current_cooldown -= delta
		return RUNNING

	var target = blackboard.get_var(target_var)
	if not is_instance_valid(target):
		return FAILURE

	var distance = agent.global_position.distance_to(target.global_position)
	
	if distance <= attack_range:
		_perform_frost_attack(target)
		_current_cooldown = attack_cooldown
		return SUCCESS

	return FAILURE

func _perform_frost_attack(target: Node2D) -> void:
	if target.has_method("take_damage"):
		target.take_damage(frost_damage)
	
	if target.has_method("apply_frost_effect"):
		target.apply_frost_effect(frost_effect_duration)

	if agent.has_method("play_frost_attack_animation"):
		agent.play_frost_attack_animation() 