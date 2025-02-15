extends BTAction

@export var target_type: String = "Enemy"
@export var target_var: StringName = &"target"
@export var targets_var: StringName = &"known_targets"
@export var detection_radius: float = 300.0


func _is_within_radius(target) -> bool:
	var distance = agent.global_position.distance_to(target.global_position)
	if distance <= detection_radius:
		# Check line of sight using raycasting
		var space_state = agent.get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(
			agent.global_position, target.global_position, 1  # Collision mask for walls/obstacles
		)
		var result = space_state.intersect_ray(query)

		# If no collision or first collision is the target
		return !result || result.collider == target

	return false
