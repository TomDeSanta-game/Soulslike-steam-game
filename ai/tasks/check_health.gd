extends BTAction

@export var health_threshold: float = 0.5  # 50% health threshold

func _tick(_delta: float) -> Status:
	if not agent.has_method("get_health_percentage"):
		push_error("Agent does not have get_health_percentage method")
		return FAILURE
	
	var health_percentage = agent.get_health_percentage()
	
	if health_percentage <= health_threshold:
		return SUCCESS
	
	return FAILURE 