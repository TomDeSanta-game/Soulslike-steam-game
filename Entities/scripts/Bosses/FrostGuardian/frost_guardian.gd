# Version 1.0.0
extends BossBase
class_name FrostGuardian

@export_group("Frost Guardian Properties")
@export var ice_damage_multiplier: float = 0.4
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
enum BossState { IDLE, MOVING, ATTACKING }

var current_state: BossState = BossState.IDLE
var previous_state: BossState = BossState.IDLE

# Add a variable to track the last distance to target for smoother transitions
var last_target_distance: float = 0.0
# Add a movement threshold to prevent jittering
var movement_threshold: float = 10.0
# Add a timer to control attack frequency
var attack_delay_timer: float = 0.0

# Add is_hurt state at the top with other state variables
var is_hurt: bool = false
var should_play_hurt: bool = false


func _ready() -> void:
	# Do not call super._ready() to avoid health manager initialization
	
	# Set initial health values
	max_health = 200.0  # Reduced boss health from 1000 to 200
	current_health = max_health
	
	# Emit boss-specific signals with correct health values
	SignalBus.boss_spawned.emit(self)
	SignalBus.boss_damaged.emit(self, current_health, max_health)

	# Disable behavior tree
	var bt_node = get_node_or_null("BTPlayer")
	if bt_node:
		bt_node.set_process(false)
		bt_node.set_physics_process(false)
		bt_node.set_process_input(false)

	# Set Frost Guardian specific properties
	attack_damage = 10.0  # Base damage of 10
	back_damage = 20.0  # Higher back damage for Frost Guardian
	back_damage_cooldown = 1.5  # Custom cooldown for back damage

	# Setup back box for back damage
	setup_back_box()
	if back_box:
		back_box.monitoring = true
		back_box.monitorable = false
		if back_box.get_node_or_null("CollisionShape2D"):
			back_box.get_node("CollisionShape2D").disabled = false

	# Create attack timer
	frost_attack_timer = Timer.new()
	frost_attack_timer.name = "FrostAttackTimer"
	frost_attack_timer.one_shot = true
	frost_attack_timer.timeout.connect(_on_frost_attack_timer_timeout)
	add_child(frost_attack_timer)

	# Set collision layers
	collision_layer = C_Layers.LAYER_BOSS
	collision_mask = C_Layers.MASK_BOSS

	_setup_detection_area()

	if boss_hitbox:
		boss_hitbox.position = Vector2(50, 5)
		boss_hitbox.active = false
		boss_hitbox.damage = attack_damage
		boss_hitbox.hitbox_owner = self
		boss_hitbox.monitoring = true
		boss_hitbox.monitorable = false
		boss_hitbox.show()

		boss_hitbox.set_deferred("collision_layer", C_Layers.LAYER_HITBOX)
		boss_hitbox.set_deferred("collision_mask", C_Layers.LAYER_HURTBOX)
		boss_hitbox.set_deferred("monitoring", true)
		boss_hitbox.set_deferred("monitorable", false)

		if boss_hitbox.area_entered.is_connected(_on_hitbox_area_entered):
			boss_hitbox.area_entered.disconnect(_on_hitbox_area_entered)
		boss_hitbox.area_entered.connect(_on_hitbox_area_entered)

	if boss_hurtbox:
		boss_hurtbox.position = Vector2(0, 2.5)
		boss_hurtbox.active = true
		boss_hurtbox.hurtbox_owner = self
		boss_hurtbox.collision_layer = C_Layers.LAYER_HURTBOX
		boss_hurtbox.collision_mask = C_Layers.LAYER_HITBOX
		boss_hurtbox.monitoring = true
		boss_hurtbox.monitorable = true
		
		# Connect hurtbox signals - ensure proper type checking
		if boss_hurtbox is HurtboxComponent:
			if boss_hurtbox.has_signal("hit_taken") and not boss_hurtbox.hit_taken.is_connected(_on_hit_taken):
				boss_hurtbox.hit_taken.connect(_on_hit_taken)
		else:
			push_error("boss_hurtbox is not a HurtboxComponent!")

	# Add collision shape if not present
	var collision_shape = get_node_or_null("CollisionShape2D")
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		var capsule_shape = CapsuleShape2D.new()
		capsule_shape.radius = 30
		capsule_shape.height = 60
		collision_shape.shape = capsule_shape
		add_child(collision_shape)

	# Connect animation signals
	if animated_sprite:
		if animated_sprite.animation_finished.is_connected(_on_animation_finished):
			animated_sprite.animation_finished.disconnect(_on_animation_finished)
		animated_sprite.animation_finished.connect(_on_animation_finished)
		animated_sprite.play("Idle")

		if not animated_sprite.animation_changed.is_connected(_on_animation_changed):
			animated_sprite.animation_changed.connect(_on_animation_changed)


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
	if debug_timer >= 5.0:
		debug_timer = 0.0
		_print_debug_info()

	# Add gravity
	if not is_on_floor():
		velocity.y += 900 * delta

	# Don't process AI if being hurt
	if is_hurt:
		return

	# EXTREMELY SIMPLE APPROACH: Just basic AI without behavior tree
	if target and is_instance_valid(target):
		var distance = global_position.distance_to(target.global_position)
		var direction = (target.global_position - global_position).normalized()

		# Only update facing direction if NOT attacking
		if animated_sprite and not is_attacking:
			animated_sprite.flip_h = direction.x > 0

		if is_attacking:
			velocity.x = 0

			if animated_sprite and animated_sprite.animation != "Attack":
				animated_sprite.play("Attack")

			_handle_attack_frames()
		else:
			if distance <= attack_range and can_attack:
				velocity.x = 0
				_perform_frost_slash()
			elif distance > attack_range:
				velocity.x = direction.x * MOVEMENT_SPEEDS.RUN
				if animated_sprite and animated_sprite.animation != "Run":
					animated_sprite.play("Run")
			else:
				velocity.x = 0
				if animated_sprite and animated_sprite.animation != "Idle":
					animated_sprite.play("Idle")
	else:
		velocity.x = 0
		if animated_sprite and animated_sprite.animation != "Idle" and not is_attacking:
			animated_sprite.play("Idle")

	move_and_slide()


func _handle_attack_frames() -> void:
	if not animated_sprite or not boss_hitbox:
		return

	if animated_sprite.animation != "Attack":
		if is_attacking:
			animated_sprite.play("Attack")
		return

	var current_frame = animated_sprite.frame

	if current_frame in [6, 7, 8]:
		if not boss_hitbox.active:
			boss_hitbox.active = true
			boss_hitbox.show()
			boss_hitbox.damage = attack_damage
			boss_hitbox.set_deferred("monitoring", true)
			boss_hitbox.set_deferred("monitorable", false)

			var hitbox_position = Vector2(50, 5)
			if animated_sprite.flip_h:
				hitbox_position.x = -hitbox_position.x
			boss_hitbox.position = hitbox_position
	else:
		if boss_hitbox.active:
			boss_hitbox.active = false
			boss_hitbox.hide()
			boss_hitbox.set_deferred("monitoring", false)
			boss_hitbox.set_deferred("monitorable", false)


func _print_debug_info() -> void:
	# Only log essential debug info
	if target:
		Log.info("FrostGuardian: Distance to Target: {0}".format([global_position.distance_to(target.global_position)]))


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
			is_attacking = true
			can_attack = false
			velocity.x = 0
			current_state = BossState.ATTACKING

			if animated_sprite:
				# Force animation to stop and restart
				animated_sprite.stop()
				animated_sprite.frame = 0
				animated_sprite.play("Attack")

			frost_attack_timer.start(attack_cooldown)
			attack_delay_timer = 0.0
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

	# Don't override animations if we're being hurt
	if is_hurt:
		return

	if is_attacking and animated_sprite.animation != "Attack":
		animated_sprite.play("Attack")


func _execute_attack_pattern(attack_name: String) -> void:
	if is_attacking:
		return

	match attack_name:
		"frost_slash":
			is_attacking = true
			can_attack = false
			velocity.x = 0
			current_state = BossState.ATTACKING

			if animated_sprite:
				animated_sprite.stop()
				animated_sprite.frame = 0
				animated_sprite.play("Attack")

			frost_attack_timer.start(attack_cooldown)
			attack_delay_timer = 0.0
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
		return

	if not area is HurtboxComponent:
		return

	var hurtbox = area as HurtboxComponent
	if not hurtbox.hurtbox_owner or not hurtbox.hurtbox_owner.is_in_group("Player"):
		return

	boss_hitbox.damage = attack_damage
	hurtbox.take_hit(boss_hitbox)


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
		animated_sprite.play("Attack")

	frost_attack_timer.start(attack_cooldown)


func _on_animation_finished() -> void:
	if not animated_sprite:
		return

	match animated_sprite.animation:
		"Attack":
			is_attacking = false
			if boss_hitbox:
				boss_hitbox.active = false
			velocity.x = 0
			
			if should_play_hurt:
				# Play queued hurt animation
				should_play_hurt = false
				is_hurt = true
				animated_sprite.play("Hurt")
				
				# Create a timer to reset hurt state
				var timer = get_tree().create_timer(0.5)  # Adjust time based on animation length
				await timer.timeout
				
				is_hurt = false
				animated_sprite.play("Idle")
			else:
				animated_sprite.play("Idle")
				
			frost_attack_timer.start(attack_cooldown)
		"Death":
			queue_free()
		"Hurt":
			# If we finish the hurt animation, go back to idle
			is_hurt = false
			animated_sprite.play("Idle")
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
	if is_attacking and animated_sprite and animated_sprite.animation != "Attack":
		is_attacking = false
		if boss_hitbox:
			boss_hitbox.active = false


# Add a helper method to set facing direction
func set_facing_direction(direction_x: float) -> void:
	if not animated_sprite or is_attacking:  # Don't change direction while attacking
		return
		
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
	if body.is_in_group("Player"):
		target = body
		SignalBus.player_detected.emit(self, body)

		if bt_player and bt_player.get_blackboard():
			var blackboard = bt_player.get_blackboard()
			blackboard.set_var("target", body)
			blackboard.set_var("target_distance", global_position.distance_to(body.global_position))


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") and body == target:
		SignalBus.player_lost.emit(self, body)
		target = null

		if bt_player and bt_player.get_blackboard():
			var blackboard = bt_player.get_blackboard()
			blackboard.set_var("target", null)


func _perform_frost_slash() -> void:
	if is_attacking:
		return

	is_attacking = true
	can_attack = false
	velocity.x = 0

	if animated_sprite:
		animated_sprite.stop()
		animated_sprite.frame = 0
		animated_sprite.play("Attack")

	frost_attack_timer.start(attack_cooldown)


# Override the die method from BossBase
func die() -> void:
	if not animated_sprite:
		queue_free()
		return

	# Disable all combat and movement
	is_attacking = false
	can_attack = false
	set_physics_process(false)
	
	if boss_hitbox:
		boss_hitbox.active = false
		boss_hitbox.hide()
		boss_hitbox.set_deferred("monitoring", false)
		boss_hitbox.set_deferred("monitorable", false)
	
	if boss_hurtbox:
		boss_hurtbox.active = false
		boss_hurtbox.set_deferred("monitoring", false)
		boss_hurtbox.set_deferred("monitorable", false)

	# Play death animation
	animated_sprite.play("Death")
	
	# Wait for death animation to finish
	await animated_sprite.animation_finished
	
	# Create a timer to hide after 2.5 seconds
	var timer = get_tree().create_timer(2.5)
	await timer.timeout

	# Hide the boss and queue for deletion
	hide()
	queue_free()

	# Emit death signal
	SignalBus.boss_died.emit(self)


# Handle character death
func _on_character_died() -> void:
	die()  # Call our die method which will handle the death animation and cleanup


# Update the health change handler to handle boss health
func _on_health_changed(new_health: float, max_health_value: float) -> void:
	if max_health_value <= 0:
		return
	
	current_health = new_health
	max_health = max_health_value
	
	# Only emit boss_damaged signal
	SignalBus.boss_damaged.emit(self, current_health, max_health)
	
	if current_health <= 0 and max_health > 0:
		die()
	else:
		var health_percentage = (new_health / max_health) * 100.0
		if health_percentage <= 50.0:
			_enter_phase_two()


# Phase transition handler
func _enter_phase_two() -> void:
	attack_damage *= 1.2
	attack_cooldown *= 0.9
	frost_effect_duration *= 1.2


# Override parent's take_damage function to handle boss health
func take_damage(amount: float) -> void:
	print("Boss taking damage amount: ", amount)
	current_health -= amount
	current_health = max(0, current_health)  # Ensure health doesn't go below 0
	
	# Only emit boss_damaged signal
	SignalBus.boss_damaged.emit(self, current_health, max_health)
	
	if current_health <= 0:
		die()
	else:
		if animated_sprite:
			if is_attacking:
				# Queue hurt animation to play after attack
				should_play_hurt = true
			else:
				# Play hurt animation immediately if not attacking
				print("Playing hurt animation...")
				is_hurt = true
				velocity.x = 0  # Stop movement
				animated_sprite.stop()  # Stop current animation
				animated_sprite.play("Hurt")  # Play hurt animation
				
				# Create a timer to reset hurt state
				var timer = get_tree().create_timer(0.5)  # Adjust time based on animation length
				await timer.timeout
				
				is_hurt = false
				animated_sprite.play("Idle")


func heal(amount: float) -> void:
	current_health = min(current_health + amount, max_health)
	SignalBus.boss_damaged.emit(self, current_health, max_health)


func get_health() -> float:
	return current_health


func get_max_health() -> float:
	return max_health


func get_health_percentage() -> float:
	return (current_health / max_health) * 100.0 if max_health > 0 else 0.0


func _on_hit_taken(attacker_hitbox: Node, _defender_hurtbox: Node) -> void:
	if not attacker_hitbox or not attacker_hitbox.hitbox_owner:
		return
		
	if attacker_hitbox.hitbox_owner.is_in_group("Player"):
		print("Boss taking damage: ", attacker_hitbox.damage)
		take_damage(attacker_hitbox.damage)  # Use our own take_damage method
