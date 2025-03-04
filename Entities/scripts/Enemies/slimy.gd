extends EnemyBase
class_name SlimyEnemy

@export_group("Slimy Properties")
@export var slime_damage_multiplier: float = 0.5
@export var poison_chance: float = 0.3
@export var poison_damage: float = 2.0
@export var poison_duration: float = 3.0
@export var jump_height: float = 150.0
@export var jump_cooldown: float = 2.0
@export var collision_damage: float = 5.0
@export var collision_damage_cooldown: float = 0.8
@export var can_jump_over_gaps: bool = true

# Slime-specific variables
var can_jump: bool = true
var jump_timer: float = 0.0
var is_jumping: bool = false
var death_particles_instance = null
var can_deal_collision_damage: bool = true
var collision_damage_timer: Timer
var visible_notifier: VisibleOnScreenNotifier2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var frame_data_component: Node = $FrameDataComponent

# Slimy-specific animation variables
var has_death_particles_animation: bool = false

func _ready() -> void:
	super._ready()

	LimboConsole.register_command(die, "slimy_die")
	
	# Set Slimy specific properties
	enemy_name = "Slimy"
	attack_damage = 5.0
	attack_range = 40.0
	attack_cooldown = 1.2
	detection_range = 150.0
	max_health = 1.0  # Reduced to 1.0 so it dies in one hit
	souls_reward = 30
	xp_reward = 15
	
	# Configure AI settings
	check_floor_ahead = true
	check_walls = true
	edge_detection_distance = 25.0
	wall_detection_distance = 15.0
	
	# Set initial health
	health_manager.set_vigour(1)  # Set vigour to 1 to get exactly 10 health (1 * 10 = 10)
	
	# Configure shader parameters
	_setup_shader_parameters()
	
	# Add to slime group
	add_to_group("Slime")
	
	# Setup collision damage timer
	collision_damage_timer = Timer.new()
	collision_damage_timer.one_shot = true
	collision_damage_timer.wait_time = collision_damage_cooldown
	collision_damage_timer.timeout.connect(_on_collision_damage_timer_timeout)
	add_child(collision_damage_timer)
	
	# Setup visible notifier
	visible_notifier = VisibleOnScreenNotifier2D.new()
	visible_notifier.screen_entered.connect(_on_screen_entered)
	visible_notifier.screen_exited.connect(_on_screen_exited)
	add_child(visible_notifier)
	
	# Connect body entered signal for collision damage
	SignalBus.enemy_body_entered.connect(_on_body_entered)
	
	# Connect animation signals
	if animation_player:
		animation_player.animation_finished.connect(_on_animation_player_finished)

	# Update hitbox damage with slime-specific values
	if enemy_hitbox:
		enemy_hitbox.damage = attack_damage
		
	# Disable FrameDataComponent since we're using AnimationPlayer for attacks
	if frame_data_component:
		frame_data_component.set_process(false)
		frame_data_component.set_physics_process(false)
		frame_data_component.set_process_input(false)
		
	# Check for Slimy-specific animations
	_check_slimy_animations()
	
	# Add a timer to force die after 5 seconds
	var die_timer = Timer.new()
	die_timer.one_shot = true
	die_timer.wait_time = 5.0
	die_timer.timeout.connect(func(): die())
	add_child(die_timer)
	die_timer.start()

func _check_slimy_animations() -> void:
	if animated_sprite and animated_sprite.sprite_frames:
		var animation_names = animated_sprite.sprite_frames.get_animation_names()
		has_death_particles_animation = animation_names.has("Death_Particles")

func _setup_shader_parameters() -> void:
	if shader_material:
		# Set initial shader parameters
		shader_material.set_shader_parameter("base_color_shift", Color(0.3, 0.3, 0.35, 1.0))
		shader_material.set_shader_parameter("accent_color", Color(0.7, 0.1, 0.1, 1.0))

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	# Update jump timer
	if jump_timer > 0:
		jump_timer -= delta
		if jump_timer <= 0:
			can_jump = true

func _on_screen_entered() -> void:
	# Player is in view, notify the AI system
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		SignalBus.player_detected.emit(self, player)

func _on_screen_exited() -> void:
	# Player is out of view
	SignalBus.player_lost.emit(self, null)

# Override from EnemyBase to add jumping ability
func _can_move_safely(direction: float) -> bool:
	# First check using parent method
	var safe = super._can_move_safely(direction)
	
	# If not safe but we can jump over gaps, check if we should jump
	if not safe and can_jump_over_gaps and can_jump and is_on_floor():
		# Check if there's a gap ahead but floor beyond it
		if direction < 0 and floor_raycast_left and not floor_raycast_left.is_colliding():
			# Create a longer raycast to check if there's floor beyond the gap
			var extended_ray = RayCast2D.new()
			extended_ray.target_position = Vector2(-edge_detection_distance * 3, 50)
			extended_ray.collision_mask = C_Layers.LAYER_WORLD
			add_child(extended_ray)
			extended_ray.force_raycast_update()
			
			if extended_ray.is_colliding():
				# There's floor beyond the gap, so jump
				_perform_jump()
				safe = true
			
			extended_ray.queue_free()
		elif direction > 0 and floor_raycast_right and not floor_raycast_right.is_colliding():
			# Create a longer raycast to check if there's floor beyond the gap
			var extended_ray = RayCast2D.new()
			extended_ray.target_position = Vector2(edge_detection_distance * 3, 50)
			extended_ray.collision_mask = C_Layers.LAYER_WORLD
			add_child(extended_ray)
			extended_ray.force_raycast_update()
			
			if extended_ray.is_colliding():
				# There's floor beyond the gap, so jump
				_perform_jump()
				safe = true
			
			extended_ray.queue_free()
	
	return safe

func _perform_jump() -> void:
	if is_jumping or not can_jump:
		return
	
	is_jumping = true
	can_jump = false
	jump_timer = jump_cooldown
	
	# Calculate jump direction towards player or in current movement direction
	var jump_direction = Vector2.ZERO
	var player = get_tree().get_first_node_in_group("Player")
	if player and global_position.distance_to(player.global_position) <= detection_range:
		jump_direction = (player.global_position - global_position).normalized()
	else:
		# Use current facing direction
		jump_direction.x = 1.0 if not animated_sprite.flip_h else -1.0
	
	# Apply jump velocity
	velocity.y = -jump_height
	velocity.x = jump_direction.x * MOVEMENT_SPEEDS.CHASE * 1.5
	
	# Play jump animation if available
	if has_idle_run_animation:
		_play_animation("Idle-Run")  # Use existing animation for jump
	
	# Reset jumping state when landing
	await get_tree().create_timer(0.5).timeout
	is_jumping = false

func _deal_collision_damage(player: Node) -> void:
	if not can_deal_collision_damage:
		return
	
	# Check if player is invincible
	if player.has_method("is_player_invincible") and player.is_player_invincible():
		return
		
	# Check if player was recently hit by a hitbox
	var player_path = player.get_path()
	if HitboxComponent._global_hit_cooldown.has(player_path):
		var time_since_last_hit = Time.get_ticks_msec() - HitboxComponent._global_hit_cooldown[player_path]
		if time_since_last_hit < HitboxComponent.GLOBAL_HIT_COOLDOWN_TIME * 1000:
			return
	
	# Apply damage to player
	if player.has_method("take_damage"):
		# Set global hit cooldown to prevent multiple damage sources
		HitboxComponent._global_hit_cooldown[player_path] = Time.get_ticks_msec()
		player.take_damage(collision_damage)
	
	# Apply poison with a chance
	if randf() <= poison_chance:
		_apply_poison_effect(player)
	
	# Start cooldown timer
	can_deal_collision_damage = false
	collision_damage_timer.start()

func _on_collision_damage_timer_timeout() -> void:
	can_deal_collision_damage = true

func _on_body_entered(enemy: Node, body: Node) -> void:
	if body.is_in_group("Player") and can_deal_collision_damage and enemy == self:
		_deal_collision_damage(body)

func _apply_poison_effect(target_node: Node) -> void:
	# Check if target has a status effect manager
	if target_node.has_method("apply_status_effect"):
		target_node.apply_status_effect("poison", poison_duration, poison_damage)
	elif target_node.has_method("take_damage"):
		# If no status effect system, just apply damage over time manually
		for i in range(int(poison_duration)):
			await get_tree().create_timer(1.0).timeout
			if is_instance_valid(target_node) and target_node.has_method("take_damage"):
				target_node.take_damage(poison_damage)

# Override from EnemyBase
func take_damage(amount: float) -> void:
	# Simple flash effect when taking damage
	if shader_material:
		shader_material.set_shader_parameter("flash_modifier", 1.0)
		
		# Reset shader parameters after a short time
		await get_tree().create_timer(0.3).timeout
		if is_instance_valid(self) and shader_material:
			shader_material.set_shader_parameter("flash_modifier", 0.0)
	
	# Debug print to see damage being taken
	print("Slimy taking damage: ", amount)
	print("Slimy health before: ", health_manager.get_health())
	
	super.take_damage(amount)
	
	# Debug print after damage is applied
	print("Slimy health after: ", health_manager.get_health())
	
	# Force die if health is below 1
	if health_manager.get_health() <= 1:
		print("Slimy health critical - dying now")
		_on_character_died()

# Override from EnemyBase
func _on_character_died() -> void:
	# Spawn death particles
	if has_death_particles_animation:
		_play_animation("Death_Particles")
		await animated_sprite.animation_finished
	
	super._on_character_died()

# Override from EnemyBase
func die() -> void:
	# Emit slime death signal if needed
	SignalBus.enemy_died.emit(self)
	
	# Call parent die method
	super.die()

# Override from EnemyBase
func _update_facing_direction(face_direction: int) -> void:
	if not is_instance_valid(animated_sprite):
		return
	
	if face_direction != 0:
		var was_facing_left = animated_sprite.flip_h
		var face_left = face_direction < 0
		
		if was_facing_left != face_left:
			animated_sprite.flip_h = face_left
			
			# Update hitbox positions
			if enemy_hitbox:
				var hitbox_position = Vector2(20 if face_left else -20, 0)
				enemy_hitbox.position = hitbox_position

# Override from EnemyBase
func move(direction: float, speed: float) -> void:
	if is_attacking or is_hurt or is_dead or is_jumping:
		return
	
	# Check if it's safe to move in this direction
	if _can_move_safely(direction):
		velocity.x = direction * speed
		
		# Update facing direction
		_update_facing_direction(sign(direction))
		
		# Play run animation
		if abs(velocity.x) > 0:
			_play_movement_animation()
		else:
			_play_animation(default_animation)
	else:
		# Stop if movement is unsafe
		velocity.x = 0
		_play_animation(default_animation)

# Function to check if currently attacking
func is_currently_attacking() -> bool:
	return is_attacking

# Override from EnemyBase to use animation player instead of animated sprite for attack
func _perform_attack() -> void:
	if is_attacking:
		return
	
	is_attacking = true
	can_attack = false
	attack_timer = attack_cooldown
	velocity.x = 0
	
	# Use animation player for attack instead of animated sprite
	if animation_player and animation_player.has_animation("slime_attack"):
		animation_player.stop()
		animation_player.play("slime_attack")
		
		# Enable hitbox during attack
		if enemy_hitbox:
			enemy_hitbox.active = true
			enemy_hitbox.monitoring = true
			enemy_hitbox.monitorable = true
			enemy_hitbox.show()
	else:
		# Fallback if animation doesn't exist
		is_attacking = false
		can_attack = true

func _on_animation_player_finished(anim_name: StringName) -> void:
	if anim_name == "slime_attack":
		is_attacking = false
		if enemy_hitbox:
			enemy_hitbox.active = false
			enemy_hitbox.monitoring = false
			enemy_hitbox.monitorable = false
			enemy_hitbox.hide()
		
		# Return to idle animation
		_play_animation(default_animation)

# Override from EnemyBase
func _on_hit_landed(hitbox_node: Node, target_hurtbox: Node) -> void:
	# Only process hits from our own hitbox
	if hitbox_node != enemy_hitbox:
		return
		
	if target_hurtbox.hurtbox_owner and target_hurtbox.hurtbox_owner.has_method("take_damage"):
		# Apply poison with a chance
		if randf() <= poison_chance and target_hurtbox.hurtbox_owner.is_in_group("Player"):
			_apply_poison_effect(target_hurtbox.hurtbox_owner)

# Override from EnemyBase
func _on_animation_finished() -> void:
	if not animated_sprite:
		return
	
	match animated_sprite.animation:
		"Hurt":
			is_hurt = false
			_play_animation(default_animation)
		"Death":
			die()
		"Death_Particles":
			die()
		_:
			pass

# Force the Slimy to die immediately
func force_die() -> void:
	print("Force dying Slimy")
	health_manager.take_damage(1000)  # Take massive damage to ensure death
	_on_character_died() 