extends BTAction

@export var target_var: StringName = &"target"
@export var max_search_attempts: int = 5  # How many times to check before giving up
@export var search_interval: float = 0.5  # Time between searches

var current_attempts: int = 0
var search_timer: float = 0.0
var is_chasing: bool = false


func _tick(delta: float) -> Status:
	var target = blackboard.get_var(target_var)

	if is_instance_valid(target):
		current_attempts = 0
		is_chasing = true
		return SUCCESS

	if not is_chasing:
		return FAILURE

	search_timer += delta
	if search_timer >= search_interval:
		search_timer = 0.0
		current_attempts += 1

		if current_attempts >= max_search_attempts:
			is_chasing = false
			current_attempts = 0
			return FAILURE

	return SUCCESS
