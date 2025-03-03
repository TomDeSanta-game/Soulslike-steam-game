extends EnemyBase
class_name Slimy

@export_group("Slimy Properties")
@export var slime_damage_multiplier: float = 0.5
@export var poison_chance: float = 0.3
@export var poison_damage: float = 2.0
@export var poison_duration: float = 3.0
@export var jump_height: float = 150.0
@export var jump_cooldown: float = 2.0
@export var collision_damage: float = 5.0
@export var collision_damage_cooldown: float = 0.8

# Slime-specific variables
var can_jump: bool = true
var jump_timer: float = 0.0
var is_jumping: bool = false
var death_particles_instance = null
var can_deal_collision_damage: bool = true
var collision_damage_timer: Timer

func _ready() -> void:
	super._ready()
	
	# Set Slimy specific properties
	enemy_name = "Slimy"
	attack_damage = 8.0
	attack_range = 40.0
	attack_cooldown = 1.2
	detection_range = 150.0
	max_health = 50.0
	souls_reward = 30
	xp_reward = 15
	
	# Set initial health
	health_manager.set_vigour(int(max_health))
	
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
	
	# Connect body entered signal for collision damage
	# connect("body_entered", _on_body_entered)
	# Now using SignalBus instead
	SignalBus.enemy_body_entered.connect(_on_body_entered)

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
	
	# Check for player collision
	_check_player_collision()

func _check_player_collision() -> void:
	# Get all colliding bodies
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Check if colliding with player
		if collider and collider.is_in_group("Player") and can_deal_collision_damage:
			_deal_collision_damage(collider)

func _deal_collision_damage(player: Node) -> void:
	if not can_deal_collision_damage:
		return
	
	# Apply damage to player
	if player.has_method("take_damage"):
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

func _update_enemy_behavior(delta: float) -> void:
	# Call parent behavior first
	super._update_enemy_behavior(delta)
	
	# Add jumping behavior when chasing player
	if target and is_instance_valid(target) and can_jump and is_on_floor() and not is_attacking and not is_hurt:
		var distance = global_position.distance_to(target.global_position)
		if distance < detection_range and distance > attack_range * 0.5:
			_perform_jump()

func _perform_jump() -> void:
	if is_jumping or not can_jump:
		return
	
	is_jumping = true
	can_jump = false
	jump_timer = jump_cooldown
	
	# Calculate jump direction towards player
	var jump_direction = Vector2.ZERO
	if target and is_instance_valid(target):
		jump_direction = (target.global_position - global_position).normalized()
	
	# Apply jump velocity
	velocity.y = -jump_height
	velocity.x = jump_direction.x * MOVEMENT_SPEEDS.CHASE * 1.5
	
	# Play jump animation if available
	if animated_sprite:
		animated_sprite.play("Idle-Run")  # Use existing animation for jump
	
	# Reset jumping state when landing
	await get_tree().create_timer(0.5).timeout
	is_jumping = false

func _perform_attack() -> void:
	super._perform_attack()

func _on_hit_landed(hitbox_node: Node, target_hurtbox: Node) -> void:
	super._on_hit_landed(hitbox_node, target_hurtbox)
	
	# Apply poison effect with a chance
	if target_hurtbox.hurtbox_owner.is_in_group("Player") and randf() <= poison_chance:
		_apply_poison_effect(target_hurtbox.hurtbox_owner)

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

func take_damage(amount: float) -> void:
	# Simple flash effect when taking damage
	if shader_material:
		shader_material.set_shader_parameter("flash_modifier", 1.0)
		
		# Reset shader parameters after a short time
		await get_tree().create_timer(0.3).timeout
		if is_instance_valid(self) and shader_material:
			shader_material.set_shader_parameter("flash_modifier", 0.0)
	
	super.take_damage(amount)

func _on_character_died() -> void:
	# Spawn death particles
	if animated_sprite:
		animated_sprite.play("Death_Particles")
		await animated_sprite.animation_finished
	
	super._on_character_died()

func die() -> void:
	# Emit slime death signal if needed
	SignalBus.enemy_died.emit(self)
	
	# Call parent die method
	super.die()
