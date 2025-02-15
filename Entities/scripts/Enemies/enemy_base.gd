# Version 1.0.1
class_name EnemyBase extends CharacterBase

signal player_detected(player: Node2D)
signal player_lost(player: Node2D)

@onready var detection_area: Area2D = $DetectionArea
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var frame_data_component: FrameDataComponent = $FrameDataComponent
@onready var enemy_hitbox: HitboxComponent = %HitBox
@onready var enemy_hurtbox: HurtboxComponent = %HurtBox

@export_group("Enemy Properties")
@export var attack_damage: float = 10.0
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 1.0
@export var max_health: float = 100.0

var current_health: float
var current_direction: int = 1
var player_ref = null
var can_jump: bool = true  # Default: Can Jump
var can_attack: bool = true

const MOVEMENT_SPEEDS = {
	"WALK": 250.0,
	"RUN": 375.0,
	"CROUCH": 125.0,
}

# Attack timer
var attack_timer: Timer


func _ready() -> void:
	super._ready()  # Call parent _ready to initialize health system

	# Initialize health
	current_health = initial_health  # Use the parent class's initial_health

	# Setup hitbox and hurtbox first
	_setup_combat_components()
	
	# Then setup frame data
	_setup_frame_data()

	base_run_speed = MOVEMENT_SPEEDS.RUN
	base_crouch_speed = MOVEMENT_SPEEDS.CROUCH

	# Set team to 1 (enemies)
	team = 1

	# Setup attack timer
	attack_timer = Timer.new()
	attack_timer.one_shot = true
	attack_timer.wait_time = attack_cooldown
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)

	# Initialize health system
	health_system = HealthSystem.new()
	add_child(health_system)
	health_system._health_changed.connect(_on_health_changed)
	health_system._character_died.connect(_on_character_died)
	health_system.set_vigour(initial_vigour)


func _setup_combat_components() -> void:
	# Setup hitbox if not already in scene
	if enemy_hitbox:
		enemy_hitbox.hitbox_owner = self
		enemy_hitbox.damage = attack_damage
		enemy_hitbox.knockback_force = 200.0
		enemy_hitbox.hit_stun_duration = 0.2
		enemy_hitbox.collision_layer = 2  # Enemy layer
		enemy_hitbox.collision_mask = 4   # Player layer (to detect player hurtboxes)
		enemy_hitbox.add_to_group("Hitbox")
		hitboxes.append(enemy_hitbox)

	# Setup hurtbox if not already in scene
	if enemy_hurtbox:
		enemy_hurtbox.hurtbox_owner = self
		enemy_hurtbox.collision_layer = 2  # Enemy layer
		enemy_hurtbox.collision_mask = 4   # Player layer (to detect player hitboxes)
		hurtboxes.append(enemy_hurtbox)

	# Connect signals
	if enemy_hitbox and not enemy_hitbox.hit_landed.is_connected(_on_hit_landed):
		enemy_hitbox.hit_landed.connect(_on_hit_landed)

	if enemy_hurtbox:
		if not enemy_hurtbox.hit_taken.is_connected(_on_hit_taken):
			enemy_hurtbox.hit_taken.connect(_on_hit_taken)

	# Add self to Enemy group for proper hit detection
	add_to_group("Enemy")


func _setup_frame_data() -> void:
	if not frame_data_component:
		push_error("FrameDataComponent not found in enemy")
		return

	frame_data_component.sprite = animated_sprite
	frame_data_component.hitbox = enemy_hitbox
	frame_data_component.hurtbox = enemy_hurtbox

	# Connect frame data signals
	if animated_sprite:
		if not animated_sprite.frame_changed.is_connected(_on_frame_changed):
			animated_sprite.frame_changed.connect(_on_frame_changed)
		if not animated_sprite.animation_changed.is_connected(_on_animation_changed):
			animated_sprite.animation_changed.connect(_on_animation_changed)


# Override parent's combat functions
func _on_hit_landed(target_hurtbox: HurtboxComponent) -> void:
	# Play hit effect or sound
	if target_hurtbox.hurtbox_owner.is_in_group("Player"):
		SoundManager.play_sound(Sound.hit, "SFX")


func _on_hit_taken(attacker_hitbox: HitboxComponent) -> void:
	if attacker_hitbox.hitbox_owner and attacker_hitbox.hitbox_owner.is_in_group("Player"):
		take_damage(attacker_hitbox.damage)


func move(move_direction: int, move_speed: float) -> void:
	velocity.x = move_direction * move_speed
	_update_animation()
	_update_facing_direction(move_direction)

	move_and_slide()


func _update_facing_direction(face_direction: int) -> void:
	var is_facing_right: bool = face_direction > 0
	animated_sprite.flip_h = not is_facing_right

	# Update hitboxes based on direction
	for box in hitboxes:
		if box:
			box.scale.x = 1 if is_facing_right else -1


func _update_animation() -> void:
	var animation_name: StringName = &"Idle"

	if not is_on_floor():
		if can_jump:
			animation_name = &"Jump"
	elif velocity.x != 0:
		animation_name = &"Run"

	animated_sprite.play(animation_name)


func perform_attack() -> void:
	if not can_attack:
		return

	# Play attack animation
	animated_sprite.play("Attack")
	
	# Start attack cooldown
	can_attack = false
	attack_timer.start()


func _on_attack_timer_timeout() -> void:
	can_attack = true
	frame_data_component.clear_active_boxes()


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.is_in_group("Player"):
		player_ref = body
		player_detected.emit(player_ref)


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and body == player_ref:
		player_lost.emit(player_ref)
		player_ref = null


func _on_frame_changed() -> void:
	frame_data_component.update_frame_data()


func _on_animation_changed() -> void:
	frame_data_component.update_frame_data()


# Override die function
func die() -> void:
	# Play death animation
	animated_sprite.play("Death")

	# Disable physics and collision
	set_physics_process(false)
	set_process(false)

	# Clear frame data and disable all hitboxes and hurtboxes
	if frame_data_component:
		frame_data_component.clear_active_boxes()

	for box in hitboxes:
		if box:
			box.queue_free()

	for box in hurtboxes:
		if box:
			box.queue_free()

	# Wait for death animation
	await animated_sprite.animation_finished
	queue_free()


# Override parent's combat functions
func take_damage(damage_amount: float) -> void:
	current_health -= damage_amount
	current_health = clamp(current_health, 0.0, max_health)
	
	if current_health <= 0:
		die()
	else:
		# Play hurt animation
		animated_sprite.play("Hurt")
		# Play hurt sound
		SoundManager.play_sound(Sound.hurt, "SFX")


func heal(heal_amount: float) -> void:
	current_health += heal_amount
	current_health = clamp(current_health, 0.0, max_health)


func _on_health_changed(new_health: float, max_health: float) -> void:
	health_changed.emit(new_health, max_health)


func _on_character_died() -> void:
	character_died.emit()
	die()


func _on_hurtbox_area_entered(_area: Area2D) -> void:
	pass  # Let hit_taken handle the damage
