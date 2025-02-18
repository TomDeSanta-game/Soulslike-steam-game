extends BTAction

@export var target_var: StringName = &"target"
@export var attack_range: float = 50.0
@export var damage: float = 10.0
@export var attack_cooldown: float = 1.0

var _current_cooldown: float = 0.0

# 080c82e8
func _tick(delta: float) -> Status:
	Log.debug("Attack tick called")

	if _current_cooldown > 0:
		_current_cooldown -= delta
		return RUNNING

	var target = blackboard.get_var(target_var)
	if not is_instance_valid(target):
		Log.warn("Attack: No valid target found")
		return FAILURE

	var distance = agent.global_position.distance_to(target.global_position)
	Log.debug("Attack: Distance to target: " + str(distance))

	if distance <= attack_range:
		Log.debug("Attack: Performing attack!")
		_perform_attack(target)
		_current_cooldown = attack_cooldown
		return SUCCESS

	return FAILURE


func _perform_attack(target: Node2D) -> void:
	Log.debug("Attack: Damage method exists: " + str(target.has_method("take_damage")))
	if target.has_method("take_damage"):
		target.take_damage(damage)

	if agent.has_method("play_attack_animation"):
		agent.play_attack_animation()
