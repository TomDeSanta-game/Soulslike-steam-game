# Version 1.0.0
extends BossBase
class_name FrostGuardian

@export_group("Frost Guardian Properties")
@export var ice_damage_multiplier: float = 1.2
@export var frost_effect_duration: float = 3.0

var is_attacking: bool = false
var attack_frame: int = 0

# Debug properties
var debug_timer: float = 0.0
var bt_player: BTPlayer
var frost_attack_timer: Timer

# Add an enum for boss states to better manage transitions
enum BossState {
	IDLE,
	MOVING,
	ATTACKING
}

var current_state: BossState = BossState.IDLE
var previous_state: BossState = BossState.IDLE

func _ready() -> void:
	Log.info("FrostGuardian: _ready called")
	super._ready()  # This will initialize health_manager
	
	# Set Frost Guardian specific properties
	boss_name = "Frost Guardian"
	attack_damage *= ice_damage_multiplier
	
	# Initialize health through health_manager
	if health_manager and health_manager.has_method("set_vigour"):
		health_manager.set_vigour(int(max_health))
	else:
		Log.info("FrostGuardian: health_manager doesn't have set_vigour method")
		if health_manager and health_manager.has_method("set_health"):
			health_manager.set_health(max_health)
	
	# Create a dedicated attack timer for this boss
	frost_attack_timer = Timer.new()
	frost_attack_timer.name = "FrostAttackTimer"
	frost_attack_timer.one_shot = true
	frost_attack_timer.timeout.connect(_on_frost_attack_timer_timeout)
	add_child(frost_attack_timer)
	Log.info("FrostGuardian: Created frost attack timer")
	
	Log.info("FrostGuardian: Setting up collision layers")
	# Set collision layers and masks for the boss itself
	collision_layer = C_Layers.LAYER_BOSS
	collision_mask = C_Layers.LAYER_WORLD | C_Layers.LAYER_PLAYER | C_Layers.LAYER_PROJECTILES
	Log.info("FrostGuardian: Collision layers set to {0} and mask to {1}".format([collision_layer, collision_mask]))
	
	# Create and configure detection area
	_setup_detection_area()
	
	# Configure hitbox and hurtbox positions and collision layers
	if boss_hitbox:
		Log.info("FrostGuardian: Configuring hitbox")
		boss_hitbox.position = Vector2(50, 5)  # Default position (will be flipped based on direction)
		boss_hitbox.active = false  # Start with hitbox inactive
		boss_hitbox.collision_layer = C_Layers.LAYER_HITBOX
		boss_hitbox.collision_mask = C_Layers.LAYER_HURTBOX  # Make sure it can hit player hurtbox
		boss_hitbox.damage = attack_damage  # Set the damage value
		boss_hitbox.hitbox_owner = self
		Log.info("FrostGuardian: Hitbox configured with layer: {0} and mask: {1}".format([boss_hitbox.collision_layer, boss_hitbox.collision_mask]))
	else:
		push_error("FrostGuardian: boss_hitbox is null!")
		
	if boss_hurtbox:
		Log.info("FrostGuardian: Configuring hurtbox")
		boss_hurtbox.position = Vector2(0, 2.5)
		boss_hurtbox.active = true  # Always active
		boss_hurtbox.collision_layer = C_Layers.LAYER_HURTBOX
		boss_hurtbox.collision_mask = C_Layers.LAYER_HITBOX  # Make sure it can be hit by player hitbox
		boss_hurtbox.hurtbox_owner = self
		Log.info("FrostGuardian: Hurtbox configured with layer: {0} and mask: {1}".format([boss_hurtbox.collision_layer, boss_hurtbox.collision_mask]))
	else:
		push_error("FrostGuardian: boss_hurtbox is null!")

	# Add collision shape if not present
	var collision_shape = get_node_or_null("CollisionShape2D")
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		var capsule_shape = CapsuleShape2D.new()
		capsule_shape.radius = 30
		capsule_shape.height = 60
		collision_shape.shape = capsule_shape
		add_child(collision_shape)
		Log.info("FrostGuardian: Added main collision shape")
	else:
		Log.info("FrostGuardian: Using existing collision shape")

	# Connect animation signals
	if animated_sprite:
		if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
			animated_sprite.animation_finished.connect(_on_animation_finished)
		animated_sprite.play("Idle")
	
	# Get and configure BTPlayer
	bt_player = get_node_or_null("BTPlayer")
	if bt_player:
		Log.info("FrostGuardian: Found BTPlayer node")
		
		# Initialize blackboard with necessary variables
		var blackboard = bt_player.get_blackboard()
		if blackboard:
			blackboard.set_var("max_health", max_health)
			
			# Get current health using the appropriate method
			var current_health_value = 0
			if health_manager and health_manager.has_method("get_vigour"):
				current_health_value = health_manager.get_vigour()
			elif health_manager and health_manager.has_method("get_health"):
				current_health_value = health_manager.get_health()
			else:
				current_health_value = max_health  # Default to max health if no method available
			
			blackboard.set_var("current_health", current_health_value)
			blackboard.set_var("attack_range", attack_range)
			blackboard.set_var("detection_range", detection_range)
			blackboard.set_var("attack_damage", attack_damage)
			blackboard.set_var("frost_effect_duration", frost_effect_duration)
			Log.info("FrostGuardian: Initialized blackboard variables")
	else:
		push_error("FrostGuardian: BTPlayer node not found!")

	Log.info("FrostGuardian: _ready completed")

func _setup_detection_area() -> void:
	# Remove existing detection area if it exists
	if detection_area:
		detection_area.queue_free()
	
	# Create new detection area
	detection_area = Area2D.new()
	detection_area.name = "DetectionArea"
	add_child(detection_area)
	
	# Create collision shape for detection area
	var detection_collision_shape = CollisionShape2D.new()
	var detection_circle_shape = CircleShape2D.new()
	detection_circle_shape.radius = detection_range  # Using detection_range from parent
	detection_collision_shape.shape = detection_circle_shape
	detection_area.add_child(detection_collision_shape)
	
	Log.info("FrostGuardian: Configuring detection area")
	detection_area.collision_layer = 0  # Detection area doesn't need a layer
	detection_area.collision_mask = C_Layers.LAYER_PLAYER  # Only detect player
	
	# Make sure detection area is monitoring and monitorable
	detection_area.monitorable = false
	detection_area.monitoring = true
	
	# Connect detection area signals
	if not detection_area.body_entered.is_connected(_on_detection_area_body_entered):
		detection_area.body_entered.connect(_on_detection_area_body_entered)
	if not detection_area.body_exited.is_connected(_on_detection_area_body_exited):
		detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	Log.info("FrostGuardian: Detection area configured with radius: {0}".format([detection_range]))
	Log.info("FrostGuardian: Detection area collision mask: {0}".format([detection_area.collision_mask]))

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	# Debug timer for periodic checks
	debug_timer += delta
	if debug_timer >= 5.0:  # Print debug info every 5 seconds
		debug_timer = 0.0
		_print_debug_info()
	
	# Update blackboard with current state
	if bt_player and bt_player.get_blackboard():
		var blackboard = bt_player.get_blackboard()
		
		# Get current health using the appropriate method
		var current_health_value = 0
		if health_manager and health_manager.has_method("get_vigour"):
			current_health_value = health_manager.get_vigour()
		elif health_manager and health_manager.has_method("get_health"):
			current_health_value = health_manager.get_health()
		
		blackboard.set_var("current_health", current_health_value)
		if target:
			blackboard.set_var("target", target)
			blackboard.set_var("target_distance", global_position.distance_to(target.global_position))
	
	# Add gravity
	if not is_on_floor():
		velocity.y += 980 * delta
	
	if is_attacking:
		_handle_attack_frames()
	else:
		_handle_movement(delta)
	
	# Always call move_and_slide()
	move_and_slide()

func _print_debug_info() -> void:
	Log.info("FrostGuardian Debug Info:")
	Log.info("- Position: {0}".format([global_position]))
	Log.info("- Velocity: {0}".format([velocity]))
	Log.info("- On Floor: {0}".format([is_on_floor()]))
	Log.info("- Has Target: {0}".format([target != null]))
	if target:
		Log.info("- Target Position: {0}".format([target.global_position]))
		Log.info("- Distance to Target: {0}".format([global_position.distance_to(target.global_position)]))
	
	if detection_area:
		# Get overlapping bodies as string
		var bodies_str = ""
		for body in detection_area.get_overlapping_bodies():
			bodies_str += body.name + ", "
		Log.info("- Overlapping Bodies: " + bodies_str)
	
	if bt_player:
		Log.info("- BTPlayer found: true")
		if bt_player.get_blackboard():
			Log.info("- Blackboard exists: true")
			# We can't list all variables, but we can check for specific ones we know about
			# For debugging, we'll just acknowledge the blackboard exists

func _handle_movement(delta: float) -> void:
	if not target or not is_instance_valid(target):
		velocity.x = 0
		if animated_sprite and not is_attacking:
			animated_sprite.play("Idle")
		current_state = BossState.IDLE
		return
	
	# Calculate direction to target
	var target_direction = (target.global_position - global_position).normalized()
	var target_distance = global_position.distance_to(target.global_position)
	
	# Always set facing direction regardless of movement
	set_facing_direction(target_direction.x)
	
	# Define clear thresholds with hysteresis to prevent jittering
	var attack_threshold = attack_range * 0.9  # Attack when within 90% of attack range
	var stop_moving_threshold = attack_range * 1.1  # Stop moving when within 110% of attack range
	var start_moving_threshold = attack_range * 1.3  # Start moving when outside 130% of attack range
	
	# Debug distance info
	if target_distance <= attack_range + 50:
		Log.info("FrostGuardian: Distance: {0}, Attack Range: {1}, Can Attack: {2}, Is Attacking: {3}, State: {4}".format(
			[target_distance, attack_range, can_attack, is_attacking, BossState.keys()[current_state]]))
	
	# Force stop movement while attacking
	if is_attacking:
		velocity.x = 0
		current_state = BossState.ATTACKING
		return
	
	# State transitions with hysteresis to prevent jittering
	match current_state:
		BossState.IDLE:
			if target_distance <= attack_threshold and can_attack:
				# In attack range - initiate attack
				velocity.x = 0
				Log.info("FrostGuardian: In attack range, initiating attack")
				_perform_frost_slash()  # Direct call to ensure it runs
				current_state = BossState.ATTACKING
			elif target_distance >= start_moving_threshold:
				# Far enough to start moving
				current_state = BossState.MOVING
				if animated_sprite and not is_attacking:
					animated_sprite.play("Run")
			else:
				# Stay idle
				velocity.x = 0
				if animated_sprite and animated_sprite.animation != "Idle" and not is_attacking:
					animated_sprite.play("Idle")
		
		BossState.MOVING:
			if target_distance <= stop_moving_threshold:
				# Close enough to stop
				velocity.x = 0
				current_state = BossState.IDLE
				if animated_sprite and not is_attacking:
					animated_sprite.play("Idle")
			else:
				# Keep moving
				var speed_factor = clamp(target_distance / 200.0, 0.5, 1.0)
				velocity.x = target_direction.x * MOVEMENT_SPEEDS.RUN * speed_factor
				if animated_sprite and animated_sprite.animation != "Run" and not is_attacking:
					animated_sprite.play("Run")
		
		BossState.ATTACKING:
			# This state is handled by the is_attacking check above
			# and will transition back to IDLE when the animation finishes
			pass
	
	# Log state changes for debugging
	if previous_state != current_state:
		Log.info("FrostGuardian: State changed from {0} to {1}".format([BossState.keys()[previous_state], BossState.keys()[current_state]]))
		previous_state = current_state

# Override detection area callbacks with debug prints
func _on_detection_area_body_entered(body: Node2D) -> void:
	Log.info("FrostGuardian: Body entered detection area: {0}".format([body.name]))
	
	# Get groups as string
	var groups_str = ""
	for group in body.get_groups():
		groups_str += group + ", "
	Log.info("FrostGuardian: Body groups: " + groups_str)
	
	if body.is_in_group("Player"):
		Log.info("FrostGuardian: Player detected")
		target = body
		SignalBus.player_detected.emit(self, body)
		
		# Update blackboard with target information
		if bt_player and bt_player.get_blackboard():
			var blackboard = bt_player.get_blackboard()
			blackboard.set_var("target", body)
			blackboard.set_var("target_distance", global_position.distance_to(body.global_position))
			Log.info("FrostGuardian: Updated blackboard with target information")

func _on_detection_area_body_exited(body: Node2D) -> void:
	Log.info("FrostGuardian: Body exited detection area: {0}".format([body.name]))
	if body.is_in_group("Player") and body == target:
		Log.info("FrostGuardian: Player lost")
		SignalBus.player_lost.emit(self, body)
		target = null
		
		# Update blackboard to clear target
		if bt_player and bt_player.get_blackboard():
			var blackboard = bt_player.get_blackboard()
			blackboard.set_var("target", null)
			Log.info("FrostGuardian: Cleared target from blackboard")

func _handle_attack_frames() -> void:
	if not animated_sprite or not boss_hitbox:
		return
		
	attack_frame = animated_sprite.frame
	
	# Activate hitbox during specific attack frames (frames 6, 7, 8)
	if attack_frame in [6, 7, 8]:
		boss_hitbox.active = true
		
		# Make sure hitbox is positioned correctly based on facing direction
		if animated_sprite.flip_h:
			# Facing left
			boss_hitbox.position.x = -50  # Fixed position for left facing
		else:
			# Facing right
			boss_hitbox.position.x = 50   # Fixed position for right facing
		
		boss_hitbox.position.y = 5  # Keep the Y position consistent
	else:
		boss_hitbox.active = false

func _on_animation_changed() -> void:
	super._on_animation_changed()
	
	if not animated_sprite:
		return
		
	is_attacking = animated_sprite.animation == "Attack"
	if not is_attacking:
		boss_hitbox.active = false

func _execute_attack_pattern(attack_name: String) -> void:
	match attack_name:
		"frost_slash":
			_perform_frost_slash()
		"ice_storm":
			_perform_ice_storm()
		"frozen_ground":
			_perform_frozen_ground()

func _perform_frost_slash() -> void:
	if not animated_sprite:
		return
	
	# Make sure we're facing the target
	if target and is_instance_valid(target):
		var target_direction = (target.global_position - global_position).normalized()
		set_facing_direction(target_direction.x)
	
	# Set attacking state
	is_attacking = true
	can_attack = false
	
	# Stop movement during attack
	velocity.x = 0
	
	# Play attack animation - ensure it's not already playing
	if animated_sprite.animation != "Attack":
		animated_sprite.play("Attack")
		SignalBus.boss_attack_started.emit(self, "frost_slash")
	
	# Start the attack cooldown timer
	frost_attack_timer.start(attack_cooldown)
	
	Log.info("FrostGuardian: Performing frost slash attack")

func _perform_ice_storm() -> void:
	# Implement ice storm attack pattern
	pass

func _perform_frozen_ground() -> void:
	# Implement frozen ground attack pattern
	pass

func _on_hit_landed(_hitbox_node: Node, target_hurtbox: Node) -> void:
	super._on_hit_landed(_hitbox_node, target_hurtbox)
	
	# Apply frost effect to the target
	if target_hurtbox.hurtbox_owner.has_method("apply_frost_effect"):
		target_hurtbox.hurtbox_owner.apply_frost_effect(frost_effect_duration)

func _on_phase_transition() -> void:
	match current_phase:
		1:  # Phase 2 transition (70% health)
			attack_damage *= 1.2
			attack_cooldown *= 0.9
		2:  # Phase 3 transition (30% health)
			attack_damage *= 1.3
			attack_cooldown *= 0.8
			frost_effect_duration *= 1.5

func play_frost_attack_animation() -> void:
	if not animated_sprite:
		return
	
	is_attacking = true
	animated_sprite.play("Attack")
	
	# Enable hitbox during attack animation
	if boss_hitbox:
		boss_hitbox.active = true
		boss_hitbox.damage = attack_damage * ice_damage_multiplier
	
	# Wait for animation to finish
	await animated_sprite.animation_finished
	
	is_attacking = false
	if boss_hitbox:
		boss_hitbox.active = false

func _on_animation_finished() -> void:
	if not animated_sprite:
		return
	
	Log.info("FrostGuardian: Animation finished: {0}".format([animated_sprite.animation]))
	
	match animated_sprite.animation:
		"Attack":
			is_attacking = false
			if boss_hitbox:
				boss_hitbox.active = false
			
			# Explicitly set to Idle to prevent getting stuck
			animated_sprite.play("Idle")
			current_state = BossState.IDLE
			Log.info("FrostGuardian: Attack animation finished, returning to Idle")
		"Death":
			queue_free()
		_:
			pass

# Method to manually trigger the behavior tree
func perform_attack(attack_name: String) -> void:
	if not can_attack or is_attacking:
		return
		
	_execute_attack_pattern(attack_name)

func _on_frost_attack_timer_timeout() -> void:
	can_attack = true
	Log.info("FrostGuardian: Attack timer timeout, can attack again. Is attacking: {0}".format([is_attacking]))
	
	# If we got stuck in the attack state somehow, reset it
	if is_attacking and animated_sprite and animated_sprite.animation != "Attack":
		is_attacking = false
		if boss_hitbox:
			boss_hitbox.active = false

# Add a helper method to set facing direction
func set_facing_direction(direction_x: float) -> void:
	if animated_sprite:
		var was_flipped = animated_sprite.flip_h
		animated_sprite.flip_h = direction_x < 0
		
		# Only update hitbox position if the direction actually changed
		if was_flipped != animated_sprite.flip_h and boss_hitbox:
			if animated_sprite.flip_h:
				# Facing left
				boss_hitbox.position.x = -50  # Fixed position for left facing
			else:
				# Facing right
				boss_hitbox.position.x = 50   # Fixed position for right facing
			
			boss_hitbox.position.y = 5  # Keep the Y position consistent

# Helper method to check if the boss is currently attacking
func is_currently_attacking() -> bool:
	return is_attacking
