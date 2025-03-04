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

# Add chase speed
var chase_speed: float = 250.0  # Faster speed when chasing
var patrol_speed: float = 150.0  # Normal patrol speed

# Patrol variables
var patrol_enabled: bool = true
var patrol_wait_time: float = 2.0
var patrol_timer: float = 0.0
var is_patrolling: bool = false
var initial_position: Vector2
var patrol_points: Array[Vector2] = [
	Vector2(-400, 0),  # Left point (much wider patrol)
	Vector2(400, 0),   # Right point
	Vector2(0, 0),     # Center point
]

func _ready() -> void:
	# Do not call super._ready() to avoid health manager initialization

	LimboConsole.register_command(die, "boss_die")
	
	# Store initial position for patrol points
	initial_position = global_position
	
	# Convert patrol points to global coordinates
	var global_patrol_points: Array[Vector2] = []
	for point in patrol_points:
		global_patrol_points.append(initial_position + point)
	
	# Register patrol points with global coordinates
	PatrolPoint.register_patrol_points("frost_guardian", global_patrol_points)
	
	# Set initial health values
	max_health = 250.0  # Updated health value
	current_health = max_health
	
	# Emit initial signals
	SignalBus.emit_signal("boss_spawned", self)
	SignalBus.emit_signal("boss_damaged", self, current_health, max_health)

	# Disable behavior tree
	var bt_node = get_node_or_null("BTPlayer")
	if bt_node:
		bt_node.set_process(false)
		bt_node.set_physics_process(false)
		bt_node.set_process_input(false)

	# Set Frost Guardian specific properties with FIXED damage values
	attack_damage = 5.0  # Reduced from 10.0
	back_damage = 2.5    # Reduced from 5.0
	attack_cooldown = 1.5  # Attack cooldown
	back_damage_cooldown = 1.5  # Back damage cooldown

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
		print("Setting up boss hitbox")
		# CRITICAL: Completely disable hitbox at start
		boss_hitbox.active = false
		boss_hitbox.monitoring = false
		boss_hitbox.monitorable = false
		boss_hitbox.hide()
		boss_hitbox.damage = attack_damage  # Set damage
		boss_hitbox.hitbox_owner = self     # Set owner
		boss_hitbox.position = Vector2(75, 5)
		boss_hitbox.collision_layer = C_Layers.LAYER_HITBOX
		boss_hitbox.collision_mask = C_Layers.LAYER_HURTBOX
		
		# CRITICAL: Disable collision shape
		if boss_hitbox.get_node_or_null("CollisionShape2D"):
			boss_hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)

		# Ensure hitbox is properly connected
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
		
		# Add to boss hurtbox group to prevent self-collision
		boss_hurtbox.add_to_group("Boss_Hurtbox")
		
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
	# Add gravity
	if not is_on_floor():
		velocity.y += 900 * delta
	
	# Don't process AI if being hurt, dead, or attacking
	if is_hurt or not is_instance_valid(self) or current_health <= 0:
		# SAFETY: Ensure hitbox is disabled when not in normal state
		if boss_hitbox:
			_disable_hitbox()
		move_and_slide()
		return
	
	# If attacking, only handle attack frames and movement stop
	if is_attacking:
		velocity.x = 0
		_handle_attack_frames()
		move_and_slide()
		return
	
	# SAFETY: Ensure hitbox is disabled when not attacking
	if boss_hitbox and not is_attacking:
		_disable_hitbox()
	
	# Handle chase or patrol only when not attacking
	if target and is_instance_valid(target):
		var distance = global_position.distance_to(target.global_position)
		if distance <= detection_range:
			chase_player()
		elif patrol_enabled:
			handle_patrol(delta)
	elif patrol_enabled:
		handle_patrol(delta)
	
	# Always call move_and_slide at the end
	move_and_slide()


func _handle_attack_frames() -> void:
	if not animated_sprite or not boss_hitbox:
		return

	if animated_sprite.animation != "Attack":
		_disable_hitbox()
		return

	var current_frame = animated_sprite.frame
	
	# Only activate hitbox during specific attack frames
	if current_frame in [6, 7, 8]:
		boss_hitbox.damage = attack_damage  # Ensure damage is set before enabling
		_enable_hitbox()
		
		# Position the hitbox based on facing direction
		var hitbox_position = Vector2(75 if animated_sprite.flip_h else -75, 5)
		boss_hitbox.position = hitbox_position
		
		# Check for player hit immediately
		var player = get_tree().get_first_node_in_group("Player")
		if player:
			var hitbox_global_pos = boss_hitbox.global_position
			var player_pos = player.global_position
			var attack_reach = 75
			
			var x_distance = abs(player_pos.x - hitbox_global_pos.x)
			var y_distance = abs(player_pos.y - hitbox_global_pos.y)
			
			var is_in_range = false
			if animated_sprite.flip_h:  # If facing right
				is_in_range = player_pos.x >= hitbox_global_pos.x and x_distance <= attack_reach
			else:  # If facing left
				is_in_range = player_pos.x <= hitbox_global_pos.x and x_distance <= attack_reach
			
			is_in_range = is_in_range and y_distance <= 30
			
			if is_in_range and player.has_method("take_damage"):
				player.take_damage(attack_damage)  # Use consistent damage value
	else:
		_disable_hitbox()


func _print_debug_info() -> void:
	# Only log essential debug info
	if target:
		Log.info("FrostGuardian: Distance to Target: {0}".format([global_position.distance_to(target.global_position)]))


func _handle_movement(delta: float) -> void:
	# Don't handle movement if attacking
	if is_attacking:
		velocity.x = 0
		return

	if not target or not is_instance_valid(target):
		velocity.x = 0
		if animated_sprite and not is_attacking:
			animated_sprite.play("Idle")
		return

	var target_direction = (target.global_position - global_position).normalized()
	var target_distance = global_position.distance_to(target.global_position)

	# More responsive distance tracking
	last_target_distance = target_distance

	# Update facing direction immediately only if not attacking
	if abs(target_direction.x) > 0.1 and not is_attacking:
		set_facing_direction(target_direction.x)

	# Attack logic with commitment
	if target_distance <= attack_range and can_attack and not is_attacking:
		velocity.x = lerp(velocity.x, 0.0, 0.5)  # Faster stop
		
		if abs(velocity.x) < 20:
			attack_delay_timer += delta
			if attack_delay_timer >= 0.1:
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
	else:
		attack_delay_timer = 0.0
		
		# Movement only if not attacking
		if not is_attacking:
			if target_distance > attack_range * 1.2:
				var speed_factor = clamp(target_distance / 200.0, 0.7, 1.0)
				var target_velocity = target_direction.x * MOVEMENT_SPEEDS.RUN * speed_factor
				velocity.x = lerp(velocity.x, target_velocity, 0.2)
			else:
				velocity.x = lerp(velocity.x, 0.0, 0.3)

	# Update animations only if not attacking
	if not is_attacking:
		if abs(velocity.x) > 5:
			if animated_sprite and animated_sprite.animation != "Run":
				animated_sprite.play("Run")
		else:
			if animated_sprite and animated_sprite.animation != "Idle":
				animated_sprite.play("Idle")


func _on_animation_changed() -> void:
	if not animated_sprite:
		return

	# Don't override animations if we're being hurt or attacking
	if is_hurt or is_attacking:
		return

	# Only allow attack animation to play if we're actually attacking
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
	if not boss_hitbox or not boss_hitbox.active or not boss_hitbox.monitoring:
		return
		
	# Skip if hitting our own hurtbox or another boss's hurtbox
	if area.is_in_group("Boss_Hurtbox"):
		return
	
	var is_player_hurtbox = area.is_in_group("Player_Hurtbox") or (area.get_parent() and area.get_parent().is_in_group("Player"))
	if not is_player_hurtbox:
		return

	if area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage(attack_damage)  # Use base attack damage


func _on_phase_transition() -> void:
	# Remove damage multipliers in phase transitions
	match current_phase:
		1:  # Phase 2 transition (70% health)
			attack_cooldown *= 0.9
		2:  # Phase 3 transition (30% health)
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
			_disable_hitbox()  # SAFETY: Ensure hitbox is disabled after attack
			velocity.x = 0
			animated_sprite.play("Idle")
			frost_attack_timer.start(attack_cooldown)
		"Death":
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
	if not animated_sprite or is_attacking:  # Never change direction while attacking
		return
		
	var was_flipped = animated_sprite.flip_h
	animated_sprite.flip_h = direction_x > 0
	
	if was_flipped != animated_sprite.flip_h:
		update_hitbox_position()

func update_hitbox_position() -> void:
	if not boss_hitbox:
		return
		
	# Set hitbox position based on facing direction
	boss_hitbox.position = Vector2(75 if animated_sprite.flip_h else -75, 5)


# Helper method to check if currently attacking
func is_currently_attacking() -> bool:
	return is_attacking


# Override detection area callbacks with debug prints
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target = body
		SignalBus.player_detected.emit(self, body)
		patrol_enabled = false  # Stop patrolling when player detected

		if bt_player and bt_player.get_blackboard():
			var blackboard = bt_player.get_blackboard()
			blackboard.set_var("target", body)
			blackboard.set_var("target_distance", global_position.distance_to(body.global_position))


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") and body == target:
		SignalBus.player_lost.emit(self, body)
		target = null
		patrol_enabled = true  # Resume patrolling when player lost

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
	print("FrostGuardian: Starting death sequence...")
	
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

	if animated_sprite:
		print("FrostGuardian: Playing death animation...")
		animated_sprite.play("Death")
		await animated_sprite.animation_finished
	
	# Hide the boss
	print("FrostGuardian: Hiding boss...")
	hide()
	
	# Grant souls and XP to the player
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		if player.has_method("add_souls"):
			player.add_souls(500)  # Grant 500 souls
		if player.has_method("add_xp"):
			player.add_xp(1000)  # Grant 1000 XP
	
	# Emit death signal first
	print("FrostGuardian: Emitting boss_died signal...")
	SignalBus.boss_died.emit(self)
	
	# Wait a short moment before showing the fell message
	print("FrostGuardian: Waiting before showing fell message...")
	await get_tree().create_timer(0.8).timeout
	
	# Show the "GREAT ENEMY FELLED" message
	print("FrostGuardian: Attempting to show fell message...")
	# Access FellLabelManager directly as an autoload singleton
	FellLabelManager.show_fell_message()
	
	# Wait for fell message duration before cleanup
	print("FrostGuardian: Waiting for cleanup...")
	await get_tree().create_timer(4.0).timeout  # Increased to match new fell message duration
	
	# Clean up
	print("FrostGuardian: Cleaning up...")
	queue_free()


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
	attack_cooldown *= 0.9
	frost_effect_duration *= 1.2


# Override parent's take_damage function to handle boss health
func take_damage(amount: float) -> void:
	if current_health <= 0:
		return
	
	# Update health with the actual damage amount
	current_health = max(0, current_health - amount)
	
	# Emit signal for health bar update
	SignalBus.boss_damaged.emit(self, current_health, max_health)
	
	# Only play hurt animation if not attacking
	if not is_attacking and animated_sprite and animated_sprite.animation != "Attack":
		is_hurt = true
		var prev_animation = animated_sprite.animation
		animated_sprite.play("Hurt")
		await animated_sprite.animation_finished
		is_hurt = false
		# Only return to previous animation if we're still alive and not attacking
		if current_health > 0 and not is_attacking:
			animated_sprite.play(prev_animation)
	
	if current_health <= 0:
		die()


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
		# Use the actual damage from the hitbox
		take_damage(attacker_hitbox.damage)
		# Let the hit_landed signal propagate for lifesteal
		SignalBus.hit_landed.emit(attacker_hitbox, _defender_hurtbox)

func handle_patrol(delta: float) -> void:
	if not is_on_floor():
		return  # Don't patrol if not on floor
		
	if patrol_timer > 0:
		patrol_timer -= delta
		if patrol_timer <= 0:
			is_patrolling = false  # Reset patrolling state when timer expires
		return
	
	if not is_patrolling:
		is_patrolling = true
		var _target = PatrolPoint.get_next_patrol_point("frost_guardian")
		move_to_point(_target)
		patrol_timer = patrol_wait_time
	else:
		# Continue moving to current target
		var _target = PatrolPoint.get_current_patrol_point("frost_guardian")
		move_to_point(_target)

func move_to_point(_target: Vector2) -> void:
	if not is_instance_valid(animated_sprite):
		return
		
	var direction = (_target - global_position).normalized()
	var distance = global_position.distance_to(_target)
	
	# Update facing direction immediately
	set_facing_direction(direction.x)
	
	if distance > 10.0:
		var target_velocity = direction.x * patrol_speed
		velocity.x = lerp(velocity.x, target_velocity, 0.2)  # Faster movement response
		
		if abs(velocity.x) > 5:  # Lower threshold for animation
			if animated_sprite.animation != "Run":
				animated_sprite.play("Run")
		else:
			if animated_sprite.animation != "Idle":
				animated_sprite.play("Idle")
	else:
		velocity.x = lerp(velocity.x, 0.0, 0.3)  # Faster stop
		if animated_sprite.animation != "Idle":
			animated_sprite.play("Idle")
		is_patrolling = false

func chase_player() -> void:
	if not target or not is_instance_valid(target) or is_attacking:
		return
	
	var direction = (target.global_position - global_position).normalized()
	var distance = global_position.distance_to(target.global_position)
	
	# Update facing direction immediately when not attacking
	if animated_sprite:
		set_facing_direction(direction.x)
	
	# Only start attack if we're not already attacking
	if distance <= attack_range and can_attack and not is_attacking:
		velocity.x = lerp(velocity.x, 0.0, 0.5)  # Faster stop
		if abs(velocity.x) < 20:  # Increased threshold
			is_attacking = true
			animated_sprite.play("Attack")
			_handle_attack_frames()
	else:
		# Chase only if not attacking
		var target_velocity = direction.x * chase_speed
		velocity.x = lerp(velocity.x, target_velocity, 0.2)
		if animated_sprite and animated_sprite.animation != "Run":
			animated_sprite.play("Run")

func _on_continuous_damage_timer_timeout() -> void:
	if _is_player_in_back_box and not is_attacking:  # Don't apply back damage during attacks
		var player = get_tree().get_first_node_in_group("Player")
		if player and player.has_method("take_damage") and can_deal_back_damage:
			player.take_damage(back_damage)  # Use base back damage
			can_deal_back_damage = false
			if has_node("BackDamageTimer"):
				get_node("BackDamageTimer").start()

# Add helper functions to manage hitbox state
func _disable_hitbox() -> void:
	if not boss_hitbox:
		return
	boss_hitbox.active = false
	boss_hitbox.monitoring = false
	boss_hitbox.monitorable = false
	boss_hitbox.hide()
	if boss_hitbox.get_node_or_null("CollisionShape2D"):
		boss_hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)

func _enable_hitbox() -> void:
	if not boss_hitbox:
		return
	boss_hitbox.damage = attack_damage  # Ensure damage is set correctly when enabling
	boss_hitbox.active = true
	boss_hitbox.monitoring = true
	boss_hitbox.monitorable = true
	boss_hitbox.show()
	if boss_hitbox.get_node_or_null("CollisionShape2D"):
		boss_hitbox.get_node("CollisionShape2D").set_deferred("disabled", false)
