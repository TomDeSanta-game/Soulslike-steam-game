extends BTAction

@export var target_var: StringName = &"target"
@export var attack_range: float = 60.0
@export var frost_damage: float = 15.0
@export var attack_cooldown: float = 1.5
@export var frost_effect_duration: float = 3.0

var _current_cooldown: float = 0.0
var _is_attacking: bool = false
var _attack_finished: bool = false

func _tick(delta: float) -> Status:
	if _current_cooldown > 0:
		_current_cooldown -= delta
		return RUNNING

	if _is_attacking:
		if _attack_finished:
			_is_attacking = false
			_attack_finished = false
			_current_cooldown = attack_cooldown
			return SUCCESS
		return RUNNING

	var target = blackboard.get_var(target_var)
	if not is_instance_valid(target):
		return FAILURE

	var distance = agent.global_position.distance_to(target.global_position)
	
	# Only attempt to attack if we're within range and not already attacking
	if distance <= attack_range:
		# Check if the agent is already attacking (via its own script)
		if agent.has_method("is_currently_attacking") and agent.is_currently_attacking():
			return RUNNING
		
		# Check if the agent has a custom can_attack property
		if "can_attack" in agent and not agent.can_attack:
			return FAILURE
		
		# Face the target before attacking
		var direction = agent.global_position.direction_to(target.global_position)
		_face_target(direction)
		
		# Start the attack
		_is_attacking = true
		_perform_frost_attack()
		
		return RUNNING
	
	return FAILURE

func _face_target(direction: Vector2) -> void:
	# Use the agent's custom method if available
	if agent.has_method("set_facing_direction"):
		agent.set_facing_direction(direction.x)
	# Fallback to direct sprite manipulation
	elif agent.has_node("AnimatedSprite2D"):
		var sprite = agent.get_node("AnimatedSprite2D")
		sprite.flip_h = direction.x < 0

func _perform_frost_attack() -> void:
	# Use the agent's custom method if available
	if agent.has_method("_perform_frost_slash"):
		agent._perform_frost_slash()
		_attack_finished = true
		return
	elif agent.has_method("perform_attack"):
		agent.perform_attack("frost_slash")
		
		# Connect to the animation_finished signal if not already connected
		if agent.has_node("AnimatedSprite2D"):
			var sprite = agent.get_node("AnimatedSprite2D")
			if not sprite.animation_finished.is_connected(_on_animation_finished):
				sprite.animation_finished.connect(_on_animation_finished)
	# Fallback to direct animation playing
	elif agent.has_node("AnimatedSprite2D"):
		var sprite = agent.get_node("AnimatedSprite2D")
		if sprite.sprite_frames.has_animation("Attack") and sprite.animation != "Attack":
			sprite.play("Attack")
			
			# Connect to the animation_finished signal if not already connected
			if not sprite.animation_finished.is_connected(_on_animation_finished):
				sprite.animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:
	_attack_finished = true
	
	# Disconnect the signal to avoid multiple connections
	if agent.has_node("AnimatedSprite2D"):
		var sprite = agent.get_node("AnimatedSprite2D")
		if sprite.animation_finished.is_connected(_on_animation_finished):
			sprite.animation_finished.disconnect(_on_animation_finished)

# Helper method to check if agent has a property
func has_property(property_name: String) -> bool:
	return property_name in agent

func _adjust_hitbox_position() -> void:
	if agent.has_node("HitBox"):
		var hitbox = agent.get_node("HitBox")
		var sprite = agent.get_node("AnimatedSprite2D")
		
		# Adjust hitbox position based on sprite direction
		if sprite and sprite.flip_h:
			# Facing left
			hitbox.position.x = -50  # Fixed position for left facing
		else:
			# Facing right
			hitbox.position.x = 50   # Fixed position for right facing
		
		hitbox.position.y = 5  # Keep the Y position consistent 