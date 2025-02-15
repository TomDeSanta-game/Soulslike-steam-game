extends BTAction

@export var target_var: StringName = &"target"
@export var speed: float = 100.0  # Renamed for clarity
@export var tolerance: float = 10.0  # Changed to float


func _tick(_delta: float) -> Status:
	var target: CharacterBody2D = blackboard.get_var(target_var)

	if not is_instance_valid(target):
		return FAILURE

	var target_position: Vector2 = target.global_position
	var direction: Vector2 = agent.global_position.direction_to(target_position)

	if abs(agent.global_position.x - target_position.x) < tolerance:
		agent.move(0.0, 0.0)  # Using explicit floats
		return SUCCESS

	agent.move(direction.x, speed)
	return RUNNING
