extends BTAction

@export var target_var: StringName = &"target"
@export var attack_range: float = 60.0
@export var frost_damage: float = 15.0
@export var attack_cooldown: float = 1.5
@export var frost_effect_duration: float = 3.0

var _current_cooldown: float = 0.0
var _is_attacking: bool = false
var _attack_finished: bool = false
var _attack_timer: float = 0.0  # Timer for fallback attack completion

func _tick(delta: float) -> Status:
	# Debug the attack state
	Log.info("FrostAttack: _tick called, cooldown={0}, is_attacking={1}, attack_finished={2}".format(
		[_current_cooldown, _is_attacking, _attack_finished]))
	
	if _current_cooldown > 0:
		_current_cooldown -= delta
		return RUNNING

	# Handle fallback timer for attack completion
	if _is_attacking and not _attack_finished:
		_attack_timer += delta
		if _attack_timer >= 1.0:  # 1 second fallback timer
			Log.info("FrostAttack: Fallback timer expired")
			_attack_finished = true
			_attack_timer = 0.0

	if _is_attacking:
		if _attack_finished:
			_is_attacking = false
			_attack_finished = false
			_current_cooldown = attack_cooldown
			Log.info("FrostAttack: Attack finished, setting cooldown to {0}".format([attack_cooldown]))
			return SUCCESS
		return RUNNING

	var target = blackboard.get_var(target_var)
	if not is_instance_valid(target):
		Log.info("FrostAttack: No valid target")
		return FAILURE

	var distance = agent.global_position.distance_to(target.global_position)
	Log.info("FrostAttack: Distance to target: {0}, attack_range: {1}".format([distance, attack_range]))
	
	# Only attempt to attack if we're within range and not already attacking
	if distance <= attack_range:
		# Check if the agent is already attacking (via its own script)
		if agent.has_method("is_currently_attacking") and agent.is_currently_attacking():
			Log.info("FrostAttack: Agent is already attacking")
			return RUNNING
		
		# Check if the agent has a custom can_attack property
		if "can_attack" in agent and not agent.can_attack:
			Log.info("FrostAttack: Agent cannot attack right now")
			return FAILURE
		
		# Face the target before attacking
		var direction = agent.global_position.direction_to(target.global_position)
		_face_target(direction)
		
		# Start the attack
		_is_attacking = true
		_attack_timer = 0.0  # Reset fallback timer
		Log.info("FrostAttack: Starting attack")
		_perform_frost_attack()
		
		return RUNNING
	
	Log.info("FrostAttack: Target not in range")
	return FAILURE

func _face_target(direction: Vector2) -> void:
	# Use the agent's custom method if available
	if agent.has_method("set_facing_direction"):
		Log.info("FrostAttack: Setting facing direction to {0}".format([direction.x]))
		agent.set_facing_direction(direction.x)
	# Fallback to direct sprite manipulation
	elif agent.has_node("AnimatedSprite2D"):
		var sprite = agent.get_node("AnimatedSprite2D")
		sprite.flip_h = direction.x < 0
		Log.info("FrostAttack: Set sprite flip_h to {0}".format([sprite.flip_h]))

func _perform_frost_attack() -> void:
	Log.info("FrostAttack: _perform_frost_attack called")
	
	# DIRECT APPROACH: Set the agent's properties directly
	if "is_attacking" in agent:
		agent.is_attacking = true
		Log.info("FrostAttack: Set agent.is_attacking = true directly")
	
	if "can_attack" in agent:
		agent.can_attack = false
		Log.info("FrostAttack: Set agent.can_attack = false directly")
	
	if agent.has_method("_perform_frost_slash"):
		Log.info("FrostAttack: Calling agent._perform_frost_slash()")
		agent._perform_frost_slash()
		# Don't set _attack_finished here, wait for animation to finish
	elif agent.has_method("perform_attack"):
		Log.info("FrostAttack: Calling agent.perform_attack('frost_slash')")
		agent.perform_attack("frost_slash")
	else:
		Log.info("FrostAttack: No attack method found, using direct animation control")
		# Direct animation control
		if agent.has_node("AnimatedSprite2D"):
			var sprite = agent.get_node("AnimatedSprite2D")
			if sprite.sprite_frames.has_animation("Attack"):
				sprite.stop()
				sprite.frame = 0
				sprite.play("Attack")
				Log.info("FrostAttack: Played Attack animation directly")
	
	# Always connect to animation_finished to know when attack is done
	if agent.has_node("AnimatedSprite2D"):
		var sprite = agent.get_node("AnimatedSprite2D")
		if not sprite.animation_finished.is_connected(_on_animation_finished):
			sprite.animation_finished.connect(_on_animation_finished)
			Log.info("FrostAttack: Connected to animation_finished signal")

func _on_animation_finished() -> void:
	Log.info("FrostAttack: Animation finished")
	_attack_finished = true
	
	# Disconnect the signal to avoid multiple connections
	if agent.has_node("AnimatedSprite2D"):
		var sprite = agent.get_node("AnimatedSprite2D")
		if sprite.animation_finished.is_connected(_on_animation_finished):
			sprite.animation_finished.disconnect(_on_animation_finished)
			Log.info("FrostAttack: Disconnected from animation_finished signal")

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
		Log.info("FrostAttack: Adjusted hitbox position to {0}".format([hitbox.position])) 