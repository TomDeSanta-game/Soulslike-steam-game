extends BTAction

@export var target_pos: String = "pos"  # Fixed reference to target position as a string key
@export var direction: String = "dir"  # Fixed reference for direction
@export var speed: float = 100.0
@export var tolerance: float = 10.0


func _tick(_delta: float) -> Status:
	var target_position: Vector2 = blackboard.get_var(target_pos, Vector2.ZERO)

	# Check if the agent is within tolerance on the X axis
	if abs(agent.global_position.x - target_position.x) < tolerance:
		return SUCCESS  # Reached the target on the X axis

	# Determine direction to move (left or right based on target position)
	var dir: float = sign(target_position.x - agent.global_position.x)
	agent.move(dir, speed)
	return RUNNING  # Action is still running, agent is moving
