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

@onready var enemy_hitbox: Node = %HitBox
@onready var enemy_hurtbox: Node = %HurtBox
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var shader_material: ShaderMaterial = null

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
	if enemy_hitbox:
		enemy_hitbox.hitbox_owner = self
		enemy_hitbox.damage = attack_damage
		enemy_hitbox.collision_layer = C_Layers.LAYER_HITBOX
		enemy_hitbox.collision_mask = C_Layers.MASK_HITBOX
		enemy_hitbox.active = false
	
	if enemy_hurtbox:
		enemy_hurtbox.hurtbox_owner = self
		enemy_hurtbox.collision_layer = C_Layers.LAYER_HURTBOX
		enemy_hurtbox.collision_mask = C_Layers.MASK_HURTBOX
	
	# Initialize patrol points
	initial_position = global_position
	_setup_patrol_points()
	
	# Add to enemy group
	add_to_group("Enemy")
	
	# Setup shader material if available
	_setup_shader()
	
	# Setup collision detection
	_setup_collision_detection()

func _setup_enemy() -> void:
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)
	else:
		# Create detection area if it doesn't exist
		_setup_detection_area()
	
	if enemy_hitbox:
		enemy_hitbox.hitbox_owner = self
		enemy_hitbox.damage = attack_damage
		if enemy_hitbox.has_signal("hit_landed"):
			enemy_hitbox.hit_landed.connect(_on_hit_landed)
	
	if enemy_hurtbox:
		enemy_hurtbox.hurtbox_owner = self
		if enemy_hurtbox.has_signal("hit_taken"):
			enemy_hurtbox.hit_taken.connect(_on_hit_taken)
	
	if animated_sprite:
		if animated_sprite.animation_finished.is_connected(_on_animation_finished):
			animated_sprite.animation_finished.disconnect(_on_animation_finished)
		animated_sprite.animation_finished.connect(_on_animation_finished)

func _setup_detection_area() -> void:
	# Create new detection area
	detection_area = Area2D.new()
	detection_area.name = "DetectionArea"
	add_child(detection_area)

	# Create collision shape for detection area
	var detection_collision_shape = CollisionShape2D.new()
	var detection_circle_shape = CircleShape2D.new()
	detection_circle_shape.radius = detection_range
	detection_collision_shape.shape = detection_circle_shape
	detection_area.add_child(detection_collision_shape)

	# Configure detection area
	detection_area.collision_layer = 0
	detection_area.collision_mask = C_Layers.LAYER_PLAYER
	detection_area.monitorable = false
	detection_area.monitoring = true

	# Connect detection area signals
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

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
	
	# Handle AI behavior
	_update_enemy_behavior(delta)
	
	# Apply movement
	move_and_slide()
	
	# Check for collisions with player after moving
	_check_player_collision()

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
			if animated_sprite and animated_sprite.animation != "Idle":
				animated_sprite.play("Idle")

func _chase_target(_delta: float) -> void:
	var direction = (target.global_position - global_position).normalized()
	var distance = global_position.distance_to(target.global_position)
	
	# Update facing direction
	_update_facing_direction(sign(direction.x))
	
	# Attack if in range
	if distance <= attack_range and can_attack:
		_perform_attack()
	else:
		# Move towards target
		velocity.x = direction.x * MOVEMENT_SPEEDS.CHASE
		if animated_sprite and animated_sprite.animation != "Run":
			animated_sprite.play("Run")

func _flee_from_target(_delta: float) -> void:
	var direction = (global_position - target.global_position).normalized()
	
	# Update facing direction
	_update_facing_direction(sign(direction.x))
	
	# Move away from target
	velocity.x = direction.x * MOVEMENT_SPEEDS.RUN
	if animated_sprite and animated_sprite.animation != "Run":
		animated_sprite.play("Run")

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
			if animated_sprite and animated_sprite.animation != "Idle":
				animated_sprite.play("Idle")
		return
	
	if is_patrolling:
		var target_point = patrol_points[current_patrol_point]
		var direction = (target_point - global_position).normalized()
		var distance = global_position.distance_to(target_point)
		
		# Update facing direction
		_update_facing_direction(sign(direction.x))
		
		if distance > 10.0:
			velocity.x = direction.x * MOVEMENT_SPEEDS.WALK
			if animated_sprite and animated_sprite.animation != "Run":
				animated_sprite.play("Run")
		else:
			# Reached patrol point, move to next one
			current_patrol_point = (current_patrol_point + 1) % patrol_points.size()
			is_patrolling = false
			patrol_timer = patrol_wait_time
			velocity.x = 0
			if animated_sprite and animated_sprite.animation != "Idle":
				animated_sprite.play("Idle")

func _perform_attack() -> void:
	if is_attacking:
		return
	
	is_attacking = true
	can_attack = false
	attack_timer = attack_cooldown
	velocity.x = 0
	
	if animated_sprite:
		animated_sprite.play("Attack")
	
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

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target = body
		SignalBus.player_detected.emit(self, body)

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") and body == target:
		SignalBus.player_lost.emit(self, body)
		target = null

func _on_hit_landed(_hitbox_node: Node, _target_hurtbox: Node) -> void:
	if _target_hurtbox.hurtbox_owner.has_method("take_damage"):
		_target_hurtbox.hurtbox_owner.take_damage(attack_damage)
	if _target_hurtbox.hurtbox_owner.is_in_group("Player"):
		# Play hit sound if needed
		pass

func _on_hit_taken(attacker_hitbox: Node, _defender_hurtbox: Node) -> void:
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
			animated_sprite.play("Idle")
		"Hurt":
			is_hurt = false
			animated_sprite.play("Idle")
		"Death":
			die()
		_:
			pass

func take_damage(amount: float) -> void:
	super.take_damage(amount)
	
	is_hurt = true
	if animated_sprite and animated_sprite.animation != "Death":
		animated_sprite.play("Hurt")
	
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
	if animated_sprite:
		animated_sprite.play("Death")
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
