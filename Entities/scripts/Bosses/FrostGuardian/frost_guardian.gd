# Version 1.0.0
extends BossBase
class_name FrostGuardian

@export_group("Frost Guardian Properties")
@export var ice_damage_multiplier: float = 1.2
@export var frost_effect_duration: float = 3.0

# Health system variables
@export var base_vigour: float = 1000.0
var current_health: float

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

# Add a variable to track the last distance to target for smoother transitions
var last_target_distance: float = 0.0
# Add a movement threshold to prevent jittering
var movement_threshold: float = 10.0
# Add a timer to control attack frequency
var attack_delay_timer: float = 0.0

func _ready() -> void:
	Log.info("FrostGuardian: _ready called")
	super._ready()  # This will initialize health_manager from parent class
	
	# Initialize health values
	current_health = max_health  # Using max_health from BossBase
	
	# Initialize health through health manager
	if health_manager:
		health_manager.set_vigour(int(base_vigour))
		
		# Connect to health signals - CRITICAL FIX: Connect to SignalBus health_changed
		if not SignalBus.health_changed.is_connected(_on_health_changed):
			SignalBus.health_changed.connect(_on_health_changed)
		
		# Get current health values
		current_health = health_manager.get_health()
		
		# Emit boss spawned signal with proper health values
		SignalBus.boss_spawned.emit(self)
		SignalBus.boss_damaged.emit(self, current_health, max_health)
		
		Log.info("FrostGuardian: Initialized with health {0}/{1}".format([current_health, max_health]))
	else:
		push_error("FrostGuardian: No health manager found!")
	
	# CRITICAL FIX: Disable the behavior tree completely
	var bt_node = get_node_or_null("BTPlayer")
	if bt_node:
		bt_node.set_process(false)
		bt_node.set_physics_process(false)
		bt_node.set_process_input(false)
		Log.info("FrostGuardian: DISABLED BEHAVIOR TREE")
	
	# Set Frost Guardian specific properties
	attack_damage *= ice_damage_multiplier
	
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
	collision_mask = C_Layers.MASK_BOSS
	Log.info("FrostGuardian: Collision layers set to {0} and mask to {1}".format([collision_layer, collision_mask]))
	
	# Create and configure detection area
	_setup_detection_area()
	
	# CRITICAL FIX: Configure hitbox and hurtbox positions and collision layers
	if boss_hitbox:
		Log.info("FrostGuardian: Configuring hitbox")
		boss_hitbox.position = Vector2(50, 5)  # Default position (will be flipped based on direction)
		boss_hitbox.active = false  # Start with hitbox inactive
		boss_hitbox.damage = attack_damage  # Set the damage value
		boss_hitbox.hitbox_owner = self
		boss_hitbox.monitoring = true  # CRITICAL FIX: Ensure monitoring is enabled
		boss_hitbox.monitorable = false  # CRITICAL FIX: We don't need to be monitorable
		boss_hitbox.show()  # CRITICAL FIX: Make sure hitbox is visible
		
		# CRITICAL FIX: Set collision layers using deferred calls
		boss_hitbox.set_deferred("collision_layer", C_Layers.LAYER_HITBOX)  # Layer 7
		boss_hitbox.set_deferred("collision_mask", C_Layers.LAYER_HURTBOX)  # Layer 9
		boss_hitbox.set_deferred("monitoring", true)
		boss_hitbox.set_deferred("monitorable", false)
		
		# CRITICAL FIX: Verify hitbox configuration
		Log.info("FrostGuardian: Initial attack_damage value: {0}".format([attack_damage]))
		Log.info("FrostGuardian: Initial hitbox damage value: {0}".format([boss_hitbox.damage]))
		
		# CRITICAL FIX: Connect to area_entered signal for hit detection
		if boss_hitbox.area_entered.is_connected(_on_hitbox_area_entered):
			boss_hitbox.area_entered.disconnect(_on_hitbox_area_entered)
		boss_hitbox.area_entered.connect(_on_hitbox_area_entered)
		Log.info("FrostGuardian: Connected hitbox area_entered signal")
		
		Log.info("FrostGuardian: Hitbox configured with damage: {0}, layer: {1}, mask: {2}, monitoring: {3}, owner: {4}".format(
			[boss_hitbox.damage, boss_hitbox.collision_layer, boss_hitbox.collision_mask, 
			boss_hitbox.monitoring, boss_hitbox.hitbox_owner.name if boss_hitbox.hitbox_owner else "null"]))
	else:
		push_error("FrostGuardian: boss_hitbox is null!")
	
	if boss_hurtbox:
		Log.info("FrostGuardian: Configuring hurtbox")
		boss_hurtbox.position = Vector2(0, 2.5)
		boss_hurtbox.active = true  # Always active
		boss_hurtbox.hurtbox_owner = self
		
		# CRITICAL FIX: Set collision layers using deferred calls
		boss_hurtbox.set_deferred("collision_layer", C_Layers.LAYER_HURTBOX)  # Layer 9
		boss_hurtbox.set_deferred("collision_mask", C_Layers.LAYER_HITBOX)  # Layer 7
		boss_hurtbox.set_deferred("monitoring", true)
		boss_hurtbox.set_deferred("monitorable", true)
		
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
		# Disconnect any existing connections to avoid duplicates
		if animated_sprite.animation_finished.is_connected(_on_animation_finished):
			animated_sprite.animation_finished.disconnect(_on_animation_finished)
		
		# Connect the signal
		animated_sprite.animation_finished.connect(_on_animation_finished)
		
		# Start with idle animation
		animated_sprite.play("Idle")
		
		# CRITICAL FIX: Connect to animation_changed signal
		if not animated_sprite.animation_changed.is_connected(_on_animation_changed):
			animated_sprite.animation_changed.connect(_on_animation_changed)
		
		Log.info("FrostGuardian: Connected animation signals")
	
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
			if health_manager and health_manager.has_method("get_health"):
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
	
	# Add gravity
	if not is_on_floor():
		velocity.y += 980 * delta
	
	# EXTREMELY SIMPLE APPROACH: Just basic AI without behavior tree
	if target and is_instance_valid(target):
		var distance = global_position.distance_to(target.global_position)
		var direction = (target.global_position - global_position).normalized()
		
		# CRITICAL FIX: Always update facing direction
		if animated_sprite:
			animated_sprite.flip_h = direction.x > 0
		
		# Debug distance info
		if distance <= attack_range + 50 and debug_timer < 0.1:
			Log.info("FrostGuardian: Distance: {0}, Attack Range: {1}, Can Attack: {2}, Is Attacking: {3}, Facing Left: {4}".format(
				[distance, attack_range, can_attack, is_attacking, animated_sprite.flip_h if animated_sprite else "no sprite"]))
		
		if is_attacking:
			# When attacking, always zero velocity
			velocity.x = 0
			
			# Force attack animation if not already playing
			if animated_sprite and animated_sprite.animation != "Attack":
				Log.info("FrostGuardian: Forcing Attack animation")
				animated_sprite.play("Attack")
			
			# Handle attack frames (hitbox activation)
			_handle_attack_frames()
		else:
			# Not attacking
			if distance <= attack_range and can_attack:
				# Stop completely before attacking
				velocity.x = 0
				
				# Start attack
				Log.info("FrostGuardian: In attack range, initiating attack, facing left: {0}".format(
					[animated_sprite.flip_h if animated_sprite else "no sprite"]))
				_perform_frost_slash()
			elif distance > attack_range:
				# Move towards target
				velocity.x = direction.x * MOVEMENT_SPEEDS.RUN
				if animated_sprite and animated_sprite.animation != "Run":
					animated_sprite.play("Run")
			else:
				# In range but can't attack yet
				velocity.x = 0
				if animated_sprite and animated_sprite.animation != "Idle":
					animated_sprite.play("Idle")
	else:
		# No target, just idle
		velocity.x = 0
		if animated_sprite and animated_sprite.animation != "Idle" and not is_attacking:
			animated_sprite.play("Idle")
	
	move_and_slide()
	
	# Debug the attack state every frame when close to player
	if target and global_position.distance_to(target.global_position) < attack_range + 50:
		if debug_timer < 0.1:  # Limit logging frequency
			if animated_sprite:
				Log.info("FrostGuardian: Current state - is_attacking={0}, animation={1}, frame={2}, velocity={3}, hitbox_active={4}, facing_left={5}".format(
					[is_attacking, animated_sprite.animation, animated_sprite.frame, velocity, 
					boss_hitbox.active if boss_hitbox else "no hitbox", 
					animated_sprite.flip_h]))

func _handle_attack_frames() -> void:
	if not animated_sprite:
		Log.info("FrostGuardian: No animated_sprite found")
		return
		
	if not boss_hitbox:
		Log.info("FrostGuardian: No boss_hitbox found")
		return
		
	# Only handle attack frames during Attack animation
	if animated_sprite.animation != "Attack":
		if is_attacking:
			# Force attack animation if we're attacking but not in the right animation
			animated_sprite.play("Attack")
		return
		
	# Get current frame
	var current_frame = animated_sprite.frame
	
	# Activate hitbox during specific frames (6, 7, 8)
	if current_frame in [6, 7, 8]:
		if not boss_hitbox.active:
			Log.info("FrostGuardian: Activating hitbox at frame {0}".format([current_frame]))
			boss_hitbox.active = true
			boss_hitbox.show()
			boss_hitbox.damage = attack_damage
			boss_hitbox.set_deferred("monitoring", true)
			boss_hitbox.set_deferred("monitorable", false)
			
			# Position hitbox based on facing direction
			var hitbox_position = Vector2(50, 5)
			if animated_sprite.flip_h:
				hitbox_position.x = -hitbox_position.x
			boss_hitbox.position = hitbox_position
			
			Log.info("FrostGuardian: Hitbox activated with damage {0} at position {1}".format([boss_hitbox.damage, boss_hitbox.position]))
	else:
		if boss_hitbox.active:
			Log.info("FrostGuardian: Deactivating hitbox at frame {0}".format([current_frame]))
			boss_hitbox.active = false
			boss_hitbox.hide()
			boss_hitbox.set_deferred("monitoring", false)
			boss_hitbox.set_deferred("monitorable", false)
			Log.info("FrostGuardian: Hitbox deactivated")

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
	# CRITICAL FIX: Don't handle movement if attacking
	if is_attacking:
		velocity.x = 0
		return
		
	if not target or not is_instance_valid(target):
		velocity.x = 0
		if animated_sprite and not is_attacking:
			animated_sprite.play("Idle")
		return
	
	# Calculate direction and distance to target
	var target_direction = (target.global_position - global_position).normalized()
	var target_distance = global_position.distance_to(target.global_position)
	
	# Always set facing direction regardless of movement
	set_facing_direction(target_direction.x)
	
	# Debug distance info
	if target_distance <= attack_range + 50:
		Log.info("FrostGuardian: Distance: {0}, Attack Range: {1}, Can Attack: {2}, Is Attacking: {3}".format(
			[target_distance, attack_range, can_attack, is_attacking]))
	
	# If attacking, don't move
	if is_attacking:
		velocity.x = 0
		return
	
	# Smooth distance transitions to prevent jittering
	if abs(target_distance - last_target_distance) < movement_threshold:
		target_distance = lerp(last_target_distance, target_distance, 0.2)
	last_target_distance = target_distance
	
	# Attack logic - only if we're in range and can attack
	if target_distance <= attack_range and can_attack:
		# Stop completely before attacking
		velocity.x = 0
		
		# Only start attack if we've been stopped for a moment
		attack_delay_timer += delta
		if attack_delay_timer >= 0.2:  # Small delay to ensure we're stopped
			Log.info("FrostGuardian: In attack range, initiating attack")
			
			# DIRECT ATTACK EXECUTION - Don't use the method to avoid any issues
			is_attacking = true
			can_attack = false
			velocity.x = 0
			current_state = BossState.ATTACKING
			
			if animated_sprite:
				# Force animation to stop and restart
				animated_sprite.stop()
				animated_sprite.frame = 0
				Log.info("FrostGuardian: Playing Attack animation directly")
				animated_sprite.play("Attack")
				
				# Verify animation is playing
				Log.info("FrostGuardian: Animation after play: {0}, frame: {1}, playing: {2}".format(
					[animated_sprite.animation, animated_sprite.frame, animated_sprite.is_playing()]))
			
			frost_attack_timer.start(attack_cooldown)
			attack_delay_timer = 0.0
			
			# Debug check to verify attack state
			Log.info("FrostGuardian: Attack initiated, is_attacking={0}, animation={1}".format(
				[is_attacking, animated_sprite.animation if animated_sprite else "none"]))
		return
	else:
		attack_delay_timer = 0.0
	
	# Movement logic with hysteresis to prevent jittering
	if target_distance > attack_range * 1.2:  # Only move if clearly outside attack range
		# Calculate speed based on distance for smoother approach
		var speed_factor = clamp(target_distance / 200.0, 0.5, 1.0)
		
		# Apply movement with smoothing
		var target_velocity = target_direction.x * MOVEMENT_SPEEDS.RUN * speed_factor
		velocity.x = lerp(velocity.x, target_velocity, 0.2)  # Smooth acceleration
		
		# Only change animation if we're actually moving at a reasonable speed and not attacking
		if abs(velocity.x) > 20 and animated_sprite and animated_sprite.animation != "Run" and not is_attacking:
			animated_sprite.play("Run")
	else:
		# Gradually slow down rather than stopping instantly
		velocity.x = lerp(velocity.x, 0.0, 0.3)
		
		# Only switch to idle if we're almost stopped and not attacking
		if abs(velocity.x) < 10 and animated_sprite and animated_sprite.animation != "Idle" and not is_attacking:
			animated_sprite.play("Idle")

func _on_animation_changed() -> void:
	if not animated_sprite:
		return
	
	Log.info("FrostGuardian: Animation changed to: {0}, is_attacking={1}".format([animated_sprite.animation, is_attacking]))
	
	# If we're attacking but the animation isn't Attack, force it back
	if is_attacking and animated_sprite.animation != "Attack":
		Log.info("FrostGuardian: Forcing back to Attack animation")
		animated_sprite.play("Attack")

func _execute_attack_pattern(attack_name: String) -> void:
	if is_attacking:
		return
		
	match attack_name:
		"frost_slash":
			# Direct attack execution
			is_attacking = true
			can_attack = false
			velocity.x = 0
			current_state = BossState.ATTACKING
			
			if animated_sprite:
				# Force animation to stop and restart
				animated_sprite.stop()
				animated_sprite.frame = 0
				Log.info("FrostGuardian: Playing Attack animation directly")
				animated_sprite.play("Attack")
				
				# Verify animation is playing
				Log.info("FrostGuardian: Animation after play: {0}, frame: {1}, playing: {2}".format(
					[animated_sprite.animation, animated_sprite.frame, animated_sprite.is_playing()]))
			
			frost_attack_timer.start(attack_cooldown)
			attack_delay_timer = 0.0
			
			# Debug check to verify attack state
			Log.info("FrostGuardian: Attack initiated, is_attacking={0}, animation={1}".format(
				[is_attacking, animated_sprite.animation if animated_sprite else "none"]))
		"ice_storm":
			_perform_ice_storm()
		"frozen_ground":
			_perform_frozen_ground()

func _perform_ice_storm() -> void:
	# Implement ice storm attack pattern
	pass

func _perform_frozen_ground() -> void:
	# Implement frozen ground attack pattern
	pass

# CRITICAL FIX: Replace _on_hit_landed with _on_hitbox_area_entered
func _on_hitbox_area_entered(area: Area2D) -> void:
	if not boss_hitbox or not boss_hitbox.active:
		Log.info("FrostGuardian: Hitbox is null or inactive")
		return
		
	if not area is HurtboxComponent:
		Log.info("FrostGuardian: Area is not a hurtbox")
		return
		
	var hurtbox = area as HurtboxComponent
	if not hurtbox.hurtbox_owner or not hurtbox.hurtbox_owner.is_in_group("Player"):
		Log.info("FrostGuardian: Hurtbox owner is not player")
		return
		
	Log.info("FrostGuardian: Valid hit on player detected")
	boss_hitbox.damage = attack_damage  # Ensure damage is set
	hurtbox.take_hit(boss_hitbox)  # Apply damage
	Log.info("FrostGuardian: Applied damage {0} to player".format([attack_damage]))

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
	# Direct attack execution
	if is_attacking:
		return
		
	is_attacking = true
	can_attack = false
	velocity.x = 0
	current_state = BossState.ATTACKING
	
	if animated_sprite:
		# Force animation to stop and restart
		animated_sprite.stop()
		animated_sprite.frame = 0
		Log.info("FrostGuardian: Playing Attack animation from play_frost_attack_animation")
		animated_sprite.play("Attack")
	
	frost_attack_timer.start(attack_cooldown)

func _on_animation_finished() -> void:
	if not animated_sprite:
		return
	
	Log.info("FrostGuardian: Animation finished: {0}".format([animated_sprite.animation]))
	
	match animated_sprite.animation:
		"Attack":
			Log.info("FrostGuardian: Attack animation finished, resetting state")
			is_attacking = false
			
			# CRITICAL FIX: Ensure hitbox is deactivated
			if boss_hitbox:
				boss_hitbox.active = false
				Log.info("FrostGuardian: Deactivated hitbox after attack")
			
			# CRITICAL FIX: Reset velocity and play Idle
			velocity.x = 0
			animated_sprite.play("Idle")
			
			# CRITICAL FIX: Start attack cooldown timer
			frost_attack_timer.start(attack_cooldown)
			Log.info("FrostGuardian: Started attack cooldown timer")
		"Death":
			queue_free()
		_:
			pass

# Method to manually trigger the behavior tree
func perform_attack(attack_name: String) -> void:
	if not can_attack or is_attacking:
		return
		
	Log.info("FrostGuardian: Manually performing attack: {0}".format([attack_name]))
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
		animated_sprite.flip_h = direction_x > 0
		
		# Only update hitbox position if the direction actually changed
		if was_flipped != animated_sprite.flip_h and boss_hitbox:
			if animated_sprite.flip_h:
				# Facing left
				boss_hitbox.position.x = -50
			else:
				# Facing right
				boss_hitbox.position.x = 50
			
			# Keep Y position consistent
			boss_hitbox.position.y = 5

# Helper method to check if currently attacking
func is_currently_attacking() -> bool:
	return is_attacking

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

func _perform_frost_slash() -> void:
	if is_attacking:
		Log.info("FrostGuardian: Already attacking, ignoring _perform_frost_slash call")
		return
	
	Log.info("FrostGuardian: EXECUTING FROST SLASH ATTACK")
	
	# Set attack state
	is_attacking = true
	can_attack = false
	velocity.x = 0
	
	# Force attack animation
	if animated_sprite:
		animated_sprite.stop()
		animated_sprite.frame = 0
		animated_sprite.play("Attack")
		Log.info("FrostGuardian: Started Attack animation, frame: {0}, playing: {1}, facing left: {2}".format(
			[animated_sprite.frame, animated_sprite.is_playing(), animated_sprite.flip_h]))
	
	# Start cooldown timer
	frost_attack_timer.start(attack_cooldown)

# Override the die method from BossBase
func die() -> void:
	if health_manager and health_manager.get_health() <= 0:
		return
		
	SignalBus.boss_died.emit(self)
	if animated_sprite:
		animated_sprite.play("Death")
		await animated_sprite.animation_finished
	super.die()  # Call parent's die method

# Handle character death
func _on_character_died() -> void:
	die()  # Call our die method which will handle the death animation and cleanup

# Update the health change handler to match SignalBus signal signature
func _on_health_changed(new_health: float, max_health_value: float) -> void:
	Log.info("FrostGuardian: Health changed signal received - new_health: {0}, max_health: {1}".format([new_health, max_health_value]))
	current_health = new_health
	
	# Emit boss damaged signal
	SignalBus.boss_damaged.emit(self, new_health, max_health)
	
	# Check for phase transition
	var health_percentage = (new_health / max_health) * 100.0
	if health_percentage <= 50.0:
		_enter_phase_two()

# Phase transition handler
func _enter_phase_two() -> void:
	attack_damage *= 1.2
	attack_cooldown *= 0.9
	frost_effect_duration *= 1.2

func take_damage(amount: float) -> void:
	if health_manager:
		health_manager.take_damage(amount)
		current_health = health_manager.get_health()

func heal(amount: float) -> void:
	if health_manager:
		health_manager.heal(amount)
		current_health = health_manager.get_health()

func get_health() -> float:
	return current_health

func get_max_health() -> float:
	return max_health  # Using max_health from BossBase

func get_health_percentage() -> float:
	return (current_health / max_health) * 100.0 if max_health > 0 else 0.0
