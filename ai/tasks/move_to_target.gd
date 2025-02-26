extends BTAction

@export var target_var: StringName = &"target"
@export var speed: float = 100.0
@export var tolerance: float = 10.0
@export var min_distance: float = 20.0  # Minimum distance to maintain from target

func _tick(_delta: float) -> Status:
	var target = blackboard.get_var(target_var)

	if not is_instance_valid(target):
		agent.velocity.x = 0.0
		
		# Play idle animation if available
		if agent.has_node("AnimatedSprite2D"):
			var sprite = agent.get_node("AnimatedSprite2D")
			if sprite.sprite_frames.has_animation("Idle"):
				sprite.play("Idle")
		
		return FAILURE

	var target_position: Vector2 = target.global_position
	var direction: Vector2 = agent.global_position.direction_to(target_position)
	var distance = agent.global_position.distance_to(target_position)

	# If we're too close to the target, don't move
	if distance < min_distance:
		agent.velocity.x = 0.0
		
		# Play idle animation if available
		if agent.has_node("AnimatedSprite2D"):
			var sprite = agent.get_node("AnimatedSprite2D")
			if sprite.sprite_frames.has_animation("Idle"):
				sprite.play("Idle")
		
		return SUCCESS

	# If we're within tolerance, stop moving
	if abs(agent.global_position.x - target_position.x) < tolerance:
		agent.velocity.x = 0.0
		return SUCCESS

	# Set velocity based on direction
	agent.velocity.x = direction.x * speed
	
	# Update sprite direction using the helper method if available
	if agent.has_method("set_facing_direction"):
		agent.set_facing_direction(direction.x)
	elif agent.has_node("AnimatedSprite2D"):
		var sprite = agent.get_node("AnimatedSprite2D")
		sprite.flip_h = direction.x < 0
	
	# Play run animation if available
	if agent.has_node("AnimatedSprite2D"):
		var sprite = agent.get_node("AnimatedSprite2D")
		if sprite.sprite_frames.has_animation("Run"):
			sprite.play("Run")
	
	return RUNNING
