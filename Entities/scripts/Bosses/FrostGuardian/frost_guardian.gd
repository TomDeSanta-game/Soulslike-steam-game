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

func _ready() -> void:
	print("FrostGuardian: _ready called")
	super._ready()  # This will initialize health_manager
	
	# Set Frost Guardian specific properties
	boss_name = "Frost Guardian"
	attack_damage *= ice_damage_multiplier
	
	# Initialize health through health_manager
	health_manager.set_vigour(int(max_health))
	
	print("FrostGuardian: Setting up collision layers")
	# Set collision layers and masks for the boss itself
	collision_layer = C_Layers.LAYER_BOSS
	collision_mask = C_Layers.MASK_BOSS | C_Layers.LAYER_WORLD  # Add world collision
	print("FrostGuardian: Collision layers set to ", collision_layer, " and mask to ", collision_mask)
	
	# Create and configure detection area
	_setup_detection_area()
	
	# Configure hitbox and hurtbox positions and collision layers
	if boss_hitbox:
		print("FrostGuardian: Configuring hitbox")
		boss_hitbox.position = Vector2(-50, 5)
		boss_hitbox.active = false  # Start with hitbox inactive
		boss_hitbox.collision_layer = C_Layers.LAYER_HITBOX
		boss_hitbox.collision_mask = C_Layers.MASK_HITBOX
		boss_hitbox.damage = attack_damage  # Set the damage value
		boss_hitbox.hitbox_owner = self
		print("FrostGuardian: Hitbox configured")
	else:
		push_error("FrostGuardian: boss_hitbox is null!")
		
	if boss_hurtbox:
		print("FrostGuardian: Configuring hurtbox")
		boss_hurtbox.position = Vector2(0, 2.5)
		boss_hurtbox.active = true  # Always active
		boss_hurtbox.collision_layer = C_Layers.LAYER_HURTBOX
		boss_hurtbox.collision_mask = C_Layers.MASK_HURTBOX
		boss_hurtbox.hurtbox_owner = self
		print("FrostGuardian: Hurtbox configured")
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
		print("FrostGuardian: Added main collision shape")
	else:
		print("FrostGuardian: Using existing collision shape")

	# Connect animation signals
	if animated_sprite:
		if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
			animated_sprite.animation_finished.connect(_on_animation_finished)
		animated_sprite.play("Idle")

	print("FrostGuardian: _ready completed")

func _setup_detection_area() -> void:
	# Remove existing detection area if it exists
	if detection_area:
		detection_area.queue_free()
	
	# Create new detection area
	detection_area = Area2D.new()
	detection_area.name = "DetectionArea"
	add_child(detection_area)
	
	# Create collision shape for detection area
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = detection_range  # Using detection_range from parent
	collision_shape.shape = circle_shape
	detection_area.add_child(collision_shape)
	
	print("FrostGuardian: Configuring detection area")
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
	
	print("FrostGuardian: Detection area configured with radius: ", detection_range)
	print("FrostGuardian: Detection area collision mask: ", detection_area.collision_mask)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	# Debug timer for periodic checks
	debug_timer += delta
	if debug_timer >= 1.0:  # Print debug info every second
		debug_timer = 0.0
		_print_debug_info()
	
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
	print("FrostGuardian Debug Info:")
	print("- Position: ", global_position)
	print("- Velocity: ", velocity)
	print("- On Floor: ", is_on_floor())
	print("- Has Target: ", target != null)
	if target:
		print("- Target Position: ", target.global_position)
		print("- Distance to Target: ", global_position.distance_to(target.global_position))
	if detection_area:
		print("- Overlapping Bodies: ", detection_area.get_overlapping_bodies())

func _handle_movement(delta: float) -> void:
	if not target or not is_instance_valid(target):
		if animated_sprite:
			animated_sprite.play("Idle")
		return
	
	# Calculate direction to target
	var direction = (target.global_position - global_position).normalized()
	var distance = global_position.distance_to(target.global_position)
	
	# Move towards target if outside attack range
	if distance > attack_range and not is_attacking:
		velocity.x = direction.x * MOVEMENT_SPEEDS.RUN
		
		if animated_sprite:
			animated_sprite.play("Run")
			animated_sprite.flip_h = direction.x < 0
	else:
		velocity.x = 0
		if can_attack:  # Using can_attack from parent
			perform_attack("frost_slash")

# Override detection area callbacks with debug prints
func _on_detection_area_body_entered(body: Node2D) -> void:
	print("FrostGuardian: Body entered detection area: ", body.name)
	print("FrostGuardian: Body groups: ", body.get_groups())
	if body.is_in_group("Player"):
		print("FrostGuardian: Player detected")
		target = body
		SignalBus.player_detected.emit(self, body)

func _on_detection_area_body_exited(body: Node2D) -> void:
	print("FrostGuardian: Body exited detection area: ", body.name)
	if body.is_in_group("Player") and body == target:
		print("FrostGuardian: Player lost")
		SignalBus.player_lost.emit(self, body)
		target = null

func _handle_attack_frames() -> void:
	if not animated_sprite or not boss_hitbox:
		return
		
	attack_frame = animated_sprite.frame
	
	# Activate hitbox during specific attack frames (adjust frame numbers as needed)
	if attack_frame in [6, 7, 8]:
		boss_hitbox.active = true
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
		
	is_attacking = true
	animated_sprite.play("Attack")
	SignalBus.boss_attack_started.emit(self, "frost_slash")

func _perform_ice_storm() -> void:
	# Implement ice storm attack pattern
	pass

func _perform_frozen_ground() -> void:
	# Implement frozen ground attack pattern
	pass

func _on_hit_landed(target_hurtbox: Node) -> void:
	super._on_hit_landed(target_hurtbox)
	
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
	
	match animated_sprite.animation:
		"Attack":
			is_attacking = false
			if boss_hitbox:
				boss_hitbox.active = false
			animated_sprite.play("Idle")
		"Death":
			queue_free()
		_:
			pass
