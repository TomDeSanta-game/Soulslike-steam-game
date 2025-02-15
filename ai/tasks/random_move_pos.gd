extends BTAction

@export_range(10.0, 100.0) var min_range: float = 40.0  # Added range constraint
@export_range(50.0, 200.0) var max_range: float = 100.0
@export var position_var: StringName = &"pos"  # Renamed for clarity
@export var direction_var: StringName = &"dir"


func _tick(_delta: float) -> Status:
	var direction: Vector2 = _generate_random_direction()
	var target_position: Vector2 = _calculate_random_position(direction)

	blackboard.set_var(position_var, target_position)
	blackboard.set_var(direction_var, direction)

	return SUCCESS


func _generate_random_direction() -> Vector2:
	return Vector2(sign(randf_range(-1.0, 1.0)), sign(randf_range(-1.0, 1.0)))


func _calculate_random_position(direction: Vector2) -> Vector2:
	var random_x = randf_range(min_range, max_range) * direction.x
	var random_y = randf_range(min_range, max_range) * direction.y
	return agent.global_position + Vector2(random_x, random_y)
