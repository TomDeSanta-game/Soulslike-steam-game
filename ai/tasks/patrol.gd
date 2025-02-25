extends BTAction

@export var patrol_path: PatrolPath
@export var speed: float = 100.0
@export var tolerance: float = 10.0
@export var position_var: StringName = &"pos"
@export var direction_var: StringName = &"dir"
@export var default_wait_time: float = 1.0

var current_index: int = 0
var wait_timer: float = 0.0
var moving_forward: bool = true


func _tick(delta: float) -> Status:
	if not patrol_path or patrol_path.waypoints.is_empty():
		return FAILURE

	var target_position = patrol_path.waypoints[current_index]
	var distance = agent.global_position.distance_to(target_position)

	if distance < tolerance:
		wait_timer += delta
		var wait_time = patrol_path.get_wait_time(current_index)

		if wait_timer >= wait_time:
			var next_index = patrol_path.get_next_waypoint_index(current_index)
			if next_index == -1:
				return FAILURE

			current_index = next_index
			wait_timer = 0.0
			return SUCCESS
		return RUNNING

	# Update movement direction
	var direction = (target_position - agent.global_position).normalized()

	# Check if there's ground ahead using floor detector
	if agent.has_method("get_floor_detector") and agent.get_floor_detector().is_colliding():
		agent.move(sign(direction.x), speed)
	else:
		# Turn around if at edge
		current_index = patrol_path.get_next_waypoint_index(current_index)
		direction *= -1

	# Update blackboard variables
	blackboard.set_var(position_var, target_position)
	blackboard.set_var(direction_var, direction)

	return RUNNING


func reset() -> void:
	current_index = 0
	wait_timer = 0.0
	moving_forward = true
