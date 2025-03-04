extends CharacterBase
class_name EnemyBase

# Signal is now handled by SignalBus

@export_group("Enemy Properties")
@export var enemy_name: String = "Enemy"
@export var attack_damage: float = 10.0
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 1.0
@export var detection_range: float = 200.0
@export var max_health: float = 100.0
@export var souls_reward: int = 50
@export var xp_reward: int = 25

@export_group("Enemy Combat")
@export var is_aggressive: bool = true
@export var patrol_enabled: bool = true
@export var patrol_range: float = 100.0
@export var patrol_wait_time: float = 2.0

@export_group("AI Settings")
@export var check_floor_ahead: bool = true
@export var check_walls: bool = true
@export var edge_detection_distance: float = 30.0
@export var wall_detection_distance: float = 20.0

@onready var enemy_hitbox: HitboxComponent = %HitBox
@onready var enemy_hurtbox: HurtboxComponent = %HurtBox
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shader_material: ShaderMaterial = null

# Raycasts for environment detection
var floor_raycast_left: RayCast2D
var floor_raycast_right: RayCast2D
var wall_raycast: RayCast2D

# State variables
var target: Node2D = null
var can_attack: bool = true
var attack_timer: float = 0.0
var is_attacking: bool = false
var is_hurt: bool = false
var is_dead: bool = false

# Patrol variables
var patrol_timer: float = 0.0
var is_patrolling: bool = false
var initial_position: Vector2
var patrol_points: Array[Vector2] = []
var current_patrol_point: int = 0
var current_direction: float = 1.0

# Animation variables
var has_idle_animation: bool = false
var has_run_animation: bool = false
var has_idle_run_animation: bool = false
var has_attack_animation: bool = false
var has_hurt_animation: bool = false
var has_death_animation: bool = false
var default_animation: String = ""

# Movement variables
const MOVEMENT_SPEEDS = {
	"WALK": 100.0,
	"RUN": 150.0,
	"CHASE": 180.0,
}

func _ready() -> void:
	super._ready()
	_setup_enemy()
	
	# Set initial health
	health_manager.set_vigour(int(max_health))
	
	# Set team to 1 (enemies)
	team = 1
	
	# Set collision layers/masks for enemy
	collision_layer = C_Layers.LAYER_ENEMY
	collision_mask = C_Layers.MASK_ENEMY
	
	# Setup hitbox and hurtbox
	_setup_hitbox_hurtbox()
	
	# Initialize patrol points
	initial_position = global_position
	_setup_patrol_points()
	
	# Add to enemy group
	add_to_group("Enemy")
	
	# Setup shader material if available
	_setup_shader()
	
	# Setup collision detection
	_setup_collision_detection()
	
	# Setup raycasts for environment detection
	_setup_raycasts()
	
	# Check available animations
	_check_available_animations()

func _setup_enemy() -> void:
	# Add hitbox and hurtbox to arrays for CharacterBase to manage
	if enemy_hitbox and not hitboxes.has(enemy_hitbox):
		hitboxes.append(enemy_hitbox)
	
	if enemy_hurtbox and not hurtboxes.has(enemy_hurtbox):
		hurtboxes.append(enemy_hurtbox)
	
	if animated_sprite:
		if animated_sprite.animation_finished.is_connected(_on_animation_finished):
			animated_sprite.animation_finished.disconnect(_on_animation_finished)
		animated_sprite.animation_finished.connect(_on_animation_finished)

func _check_available_animations() -> void:
	if not animated_sprite:
		return
		
	var animation_names = animated_sprite.sprite_frames.get_animation_names()
	
	has_idle_animation = animation_names.has("Idle")
	has_run_animation = animation_names.has("Run")
	has_idle_run_animation = animation_names.has("Idle-Run")
	has_attack_animation = animation_names.has("Attack")
	has_hurt_animation = animation_names.has("Hurt")
	has_death_animation = animation_names.has("Death")
	
	# Set default animation
	if has_idle_animation:
		default_animation = "Idle"
	elif has_idle_run_animation:
		default_animation = "Idle-Run"
	elif animation_names.size() > 0:
		default_animation = animation_names[0]
	
	# Play default animation
	if default_animation != "":
		animated_sprite.play(default_animation)

func _setup_hitbox_hurtbox() -> void:
	if enemy_hitbox:
		enemy_hitbox.hitbox_owner = self
		enemy_hitbox.damage = attack_damage
		enemy_hitbox.collision_layer = C_Layers.LAYER_HITBOX
		enemy_hitbox.collision_mask = C_Layers.MASK_HITBOX
		enemy_hitbox.active = false
		enemy_hitbox.hide()
	
	if enemy_hurtbox:
		enemy_hurtbox.hurtbox_owner = self
		enemy_hurtbox.collision_layer = C_Layers.LAYER_HURTBOX
		enemy_hurtbox.collision_mask = C_Layers.MASK_HURTBOX
		enemy_hurtbox.active = true

func _setup_raycasts() -> void:
	# Create floor detection raycasts
	floor_raycast_left = RayCast2D.new()
	floor_raycast_left.target_position = Vector2(-edge_detection_distance, 50)
	floor_raycast_left.collision_mask = C_Layers.LAYER_WORLD
	floor_raycast_left.enabled = check_floor_ahead
	add_child(floor_raycast_left)
	
	floor_raycast_right = RayCast2D.new()
	floor_raycast_right.target_position = Vector2(edge_detection_distance, 50)
	floor_raycast_right.collision_mask = C_Layers.LAYER_WORLD
	floor_raycast_right.enabled = check_floor_ahead
	add_child(floor_raycast_right)
	
	# Create wall detection raycast
	wall_raycast = RayCast2D.new()
	wall_raycast.target_position = Vector2(wall_detection_distance, 0)
	wall_raycast.collision_mask = C_Layers.LAYER_WORLD
	wall_raycast.enabled = check_walls
	add_child(wall_raycast)

func _setup_patrol_points() -> void:
	# Create default patrol points if none are set
	if patrol_points.size() == 0:
		patrol_points = [
			initial_position + Vector2(-patrol_range, 0),
			initial_position,
			initial_position + Vector2(patrol_range, 0)
		]

func _setup_shader() -> void:
	# Check if the animated sprite has a material
	if animated_sprite and animated_sprite.material is ShaderMaterial:
		shader_material = animated_sprite.material
	else:
		# Try to load the shader
		var shader_path = "res://Shaders/Enemies/slimy.gdshader"
		var shader = load(shader_path)
		if shader:
			shader_material = ShaderMaterial.new()
			shader_material.shader = shader
			if animated_sprite:
				animated_sprite.material = shader_material

func _setup_collision_detection() -> void:
	# Set up collision detection for direct body collisions
	# This will be used by child classes to implement collision damage
	set_collision_layer_value(C_Layers.LAYER_ENEMY, true)
	set_collision_mask_value(C_Layers.LAYER_PLAYER, true)

func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity.y += 900 * delta
	
	# Don't process AI if being hurt, dead, or attacking
	if is_hurt or is_dead or is_attacking:
		move_and_slide()
		return
	
	# Update attack timer
	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			can_attack = true
	
	# Update raycast directions based on facing
	_update_raycast_directions()
	
	# Handle AI behavior
	_update_enemy_behavior(delta)
	
	# Apply movement
	move_and_slide()
	
	# Check for collisions with player after moving
	_check_player_collision()

func _update_raycast_directions() -> void:
	# Update wall raycast direction based on current movement direction
	if wall_raycast:
		var facing_direction = 1.0
		if animated_sprite:
			facing_direction = -1.0 if animated_sprite.flip_h else 1.0
		
		wall_raycast.target_position.x = wall_detection_distance * facing_direction

func _check_player_collision() -> void:
	# This is a base implementation that emits the body_entered signal
	# Child classes can override or connect to this signal
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider and collider.is_in_group("Player"):
			SignalBus.enemy_body_entered.emit(self, collider)

func _update_enemy_behavior(delta: float) -> void:
	if target and is_instance_valid(target):
		var distance = global_position.distance_to(target.global_position)
		if distance <= detection_range:
			if is_aggressive:
				_chase_target(delta)
			else:
				_flee_from_target(delta)
		elif patrol_enabled:
			_handle_patrol(delta)
		else:
			# Idle behavior
			velocity.x = lerp(velocity.x, 0.0, 0.3)
			_play_animation(default_animation)

func _chase_target(_delta: float) -> void:
	var direction = (target.global_position - global_position).normalized()
	var distance = global_position.distance_to(target.global_position)
	
	# Update facing direction
	_update_facing_direction(sign(direction.x))
	
	# Attack if in range
	if distance <= attack_range and can_attack:
		_perform_attack()
	else:
		# Check if it's safe to move in this direction
		var can_move = _can_move_safely(direction.x)
		
		if can_move:
			# Move towards target
			velocity.x = direction.x * MOVEMENT_SPEEDS.CHASE
			_play_movement_animation()
		else:
			# Stop if movement is unsafe
			velocity.x = 0
			_play_animation(default_animation)

func _flee_from_target(_delta: float) -> void:
	var direction = (global_position - target.global_position).normalized()
	
	# Update facing direction
	_update_facing_direction(sign(direction.x))
	
	# Check if it's safe to move in this direction
	var can_move = _can_move_safely(direction.x)
	
	if can_move:
		# Move away from target
		velocity.x = direction.x * MOVEMENT_SPEEDS.RUN
		_play_movement_animation()
	else:
		# Stop if movement is unsafe
		velocity.x = 0
		_play_animation(default_animation)

func _handle_patrol(delta: float) -> void:
	if not is_on_floor():
		return
	
	if patrol_timer > 0:
		patrol_timer -= delta
		if patrol_timer <= 0:
			is_patrolling = true
		else:
			# Wait at current position
			velocity.x = lerp(velocity.x, 0.0, 0.3)
			_play_animation(default_animation)
		return
	
	if is_patrolling:
		var target_point = patrol_points[current_patrol_point]
		var direction = (target_point - global_position).normalized()
		var distance = global_position.distance_to(target_point)
		
		# Update facing direction
		_update_facing_direction(sign(direction.x))
		current_direction = sign(direction.x)
		
		# Check if it's safe to move in this direction
		var can_move = _can_move_safely(direction.x)
		
		if can_move and distance > 10.0:
			velocity.x = direction.x * MOVEMENT_SPEEDS.WALK
			_play_movement_animation()
		else:
			# If we can't move safely or we've reached the point
			if distance <= 10.0:
				# Reached patrol point, move to next one
				current_patrol_point = (current_patrol_point + 1) % patrol_points.size()
			else:
				# Can't move safely, reverse direction
				current_patrol_point = (current_patrol_point + 1) % patrol_points.size()
			
			is_patrolling = false
			patrol_timer = patrol_wait_time
			velocity.x = 0
			_play_animation(default_animation)

func _can_move_safely(direction: float) -> bool:
	# Check for walls
	if check_walls and wall_raycast and wall_raycast.is_colliding():
		return false
	
	# Check for floor edges
	if check_floor_ahead:
		if direction < 0 and floor_raycast_left and not floor_raycast_left.is_colliding():
			return false
		elif direction > 0 and floor_raycast_right and not floor_raycast_right.is_colliding():
			return false
	
	return true

func _perform_attack() -> void:
	if is_attacking:
		return
	
	is_attacking = true
	can_attack = false
	attack_timer = attack_cooldown
	velocity.x = 0
	
	if has_attack_animation:
		_play_animation("Attack")
	
	# Enable hitbox during attack
	if enemy_hitbox:
		enemy_hitbox.active = true
		enemy_hitbox.monitoring = true
		enemy_hitbox.monitorable = true
		enemy_hitbox.show()

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

# Helper function to play animation safely
func _play_animation(anim_name: String) -> void:
	if not animated_sprite or animated_sprite.animation == anim_name:
		return
		
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
	elif default_animation != "":
		animated_sprite.play(default_animation)

# Helper function to play movement animation
func _play_movement_animation() -> void:
	if has_idle_run_animation:
		_play_animation("Idle-Run")
	elif has_run_animation:
		_play_animation("Run")
	else:
		_play_animation(default_animation)

# Override from CharacterBase
func _on_hit_landed(hitbox_node: Node, target_hurtbox: Node) -> void:
	# Only process hits from our own hitbox
	if hitbox_node != enemy_hitbox:
		return
		
	if target_hurtbox.hurtbox_owner and target_hurtbox.hurtbox_owner.has_method("take_damage"):
		# Play hit sound if needed
		pass

# Override from CharacterBase
func _on_hit_taken(attacker_hitbox: Node, defender_hurtbox: Node) -> void:
	# Only process hits to our own hurtbox
	if defender_hurtbox != enemy_hurtbox:
		return
		
	if attacker_hitbox.hitbox_owner and attacker_hitbox.hitbox_owner.is_in_group("Player"):
		take_damage(attacker_hitbox.damage)
		
		# Flash effect when taking damage
		if shader_material:
			shader_material.set_shader_parameter("flash_modifier", 1.0)
			var flash_timer = get_tree().create_timer(0.2)
			flash_timer.timeout.connect(func(): shader_material.set_shader_parameter("flash_modifier", 0.0))

func _on_animation_finished() -> void:
	if not animated_sprite:
		return
	
	match animated_sprite.animation:
		"Attack":
			is_attacking = false
			if enemy_hitbox:
				enemy_hitbox.active = false
				enemy_hitbox.monitoring = false
				enemy_hitbox.monitorable = false
				enemy_hitbox.hide()
			_play_animation(default_animation)
		"Hurt":
			is_hurt = false
			_play_animation(default_animation)
		"Death":
			die()
		_:
			pass

func take_damage(amount: float) -> void:
	super.take_damage(amount)
	
	is_hurt = true
	if has_hurt_animation:
		_play_animation("Hurt")
	
	# Flash effect when taking damage
	if shader_material:
		shader_material.set_shader_parameter("flash_modifier", 1.0)
		var flash_timer = get_tree().create_timer(0.2)
		flash_timer.timeout.connect(func(): shader_material.set_shader_parameter("flash_modifier", 0.0))

func _on_health_changed(new_health: float, _max_health: float) -> void:
	super._on_health_changed(new_health, _max_health)
	
	if new_health <= 0 and not is_dead:
		_on_character_died()

func _on_character_died() -> void:
	is_dead = true
	
	# Disable physics and collision
	set_physics_process(false)
	if enemy_hitbox:
		enemy_hitbox.active = false
		enemy_hitbox.monitoring = false
		enemy_hitbox.monitorable = false
	if enemy_hurtbox:
		enemy_hurtbox.active = false
		enemy_hurtbox.monitoring = false
		enemy_hurtbox.monitorable = false
	
	# Play death animation
	if has_death_animation:
		_play_animation("Death")
	else:
		die()

func die() -> void:
	# Grant souls and XP to the player
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		if player.has_method("add_souls"):
			player.add_souls(souls_reward)
		if player.has_method("add_xp"):
			player.add_xp(xp_reward)
	
	# Emit death signal
	SignalBus.enemy_died.emit(self)
	
	# Queue free
	queue_free()

func get_health() -> float:
	return health_manager.get_health()

func get_max_health() -> float:
	return health_manager.get_max_health()

func get_health_percentage() -> float:
	return health_manager.get_health_percentage()

# Required move function for AI integration
func move(direction: float, speed: float) -> void:
	if is_attacking or is_hurt or is_dead:
		return
	
	# Check if it's safe to move in this direction
	if _can_move_safely(direction):
		velocity.x = direction * speed
		
		# Update facing direction
		if animated_sprite:
			animated_sprite.flip_h = direction < 0
			
			# Update hitbox positions if needed
			if enemy_hitbox:
				var hitbox_position = Vector2(20 if animated_sprite.flip_h else -20, 0)
				enemy_hitbox.position = hitbox_position
		
		# Play run animation
		if abs(velocity.x) > 0:
			_play_movement_animation()
		else:
			_play_animation(default_animation)
	else:
		# Stop if movement is unsafe
		velocity.x = 0
		_play_animation(default_animation)
