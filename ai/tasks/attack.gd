extends BTAction

@export var target_var: StringName = &"target"
@export var attack_range: float = 50.0
@export var damage: float = 10.0
@export var attack_cooldown: float = 1.0

var _current_cooldown: float = 0.0

# 080c82e8
func _tick(delta: float) -> Status:
	print("Attack tick called")  # Debug print

	if _current_cooldown > 0:
		_current_cooldown -= delta
		return RUNNING

	var target = blackboard.get_var(target_var)
	if not is_instance_valid(target):
		print("Attack: No valid target found")  # Debug print
		return FAILURE

	var distance = agent.global_position.distance_to(target.global_position)
	print("Attack: Distance to target: ", distance)  # Debug print

	if distance <= attack_range:
		print("Attack: Performing attack!")  # Debug print
		_perform_attack(target)
		_current_cooldown = attack_cooldown
		return SUCCESS

	return FAILURE


func _perform_attack(target: Node2D) -> void:
	print("Attack: Damage method exists: ", target.has_method("take_damage"))  # Debug print
	if target.has_method("take_damage"):
		target.take_damage(damage)

	if agent.has_method("play_attack_animation"):
		agent.play_attack_animation()
