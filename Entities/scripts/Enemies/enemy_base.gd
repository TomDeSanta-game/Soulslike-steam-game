# Version 1.0.1
extends CharacterBase
class_name EnemyBase

@export_group("Enemy Properties")
@export var attack_damage: float = 10.0
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 1.0
@export var detection_range: float = 200.0
@export var max_health: float = 100.0

@onready var enemy_hitbox: Node = $HitBox
@onready var enemy_hurtbox: Node = $HurtBox
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var frame_data_component: Node = $FrameDataComponent

var current_health: float
var current_direction: int = 1
var target: Node2D = null
var can_jump: bool = true  # Default: Can Jump
var can_attack: bool = true
var attack_timer: float = 0.0

const MOVEMENT_SPEEDS = {
	"WALK": 150.0,
	"RUN": 250.0,
	"CROUCH": 125.0,
}

func _ready() -> void:
	super._ready()  # Call parent _ready to initialize health system
	_setup_enemy()

	# Initialize health
	current_health = max_health

	# Set team to 1 (enemies)
	team = 1

	# Set collision layers/masks
	collision_layer = C_Layers.LAYER_ENEMY
	collision_mask = C_Layers.MASK_ENEMY
	
	if enemy_hitbox:
		enemy_hitbox.hitbox_owner = self
		enemy_hitbox.collision_layer = C_Layers.LAYER_HITBOX
		enemy_hitbox.collision_mask = C_Layers.MASK_HITBOX
	
	if enemy_hurtbox:
		enemy_hurtbox.hurtbox_owner = self
		enemy_hurtbox.collision_layer = C_Layers.LAYER_HURTBOX
		enemy_hurtbox.collision_mask = C_Layers.MASK_HURTBOX

func _setup_enemy() -> void:
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)

	if enemy_hitbox:
		enemy_hitbox.hitbox_owner = self
		enemy_hitbox.damage = attack_damage

	if enemy_hurtbox:
		enemy_hurtbox.hurtbox_owner = self

func _physics_process(delta: float) -> void:
	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			can_attack = true

func _setup_combat_components() -> void:
	# Setup hitbox
	if enemy_hitbox:
		enemy_hitbox.hitbox_owner = self
		enemy_hitbox.damage = attack_damage
		enemy_hitbox.knockback_force = 200.0
		enemy_hitbox.hit_stun_duration = 0.2
		enemy_hitbox.collision_layer = 2  # Enemy layer
		enemy_hitbox.collision_mask = 4   # Player layer
		enemy_hitbox.active = true
		if enemy_hitbox.has_signal("hit_landed"):
			enemy_hitbox.hit_landed.connect(_on_hit_landed)

	# Setup hurtbox
	if enemy_hurtbox:
		enemy_hurtbox.hurtbox_owner = self
		enemy_hurtbox.collision_layer = 2  # Enemy layer
		enemy_hurtbox.collision_mask = 4   # Player layer
		enemy_hurtbox.active = true
		if enemy_hurtbox.has_signal("hit_taken"):
			enemy_hurtbox.hit_taken.connect(_on_hit_taken)

	add_to_group("Enemy")

func _setup_frame_data() -> void:
	if not frame_data_component:
		push_error("FrameDataComponent not found in enemy")
		return
		
	if not animated_sprite:
		push_error("AnimatedSprite2D not found in enemy")
		return

	if enemy_hitbox:
		frame_data_component.hitbox = enemy_hitbox
		frame_data_component.update_frame_data()

	if enemy_hurtbox:
		frame_data_component.hurtbox = enemy_hurtbox

	if not animated_sprite.frame_changed.is_connected(_on_frame_changed):
		animated_sprite.frame_changed.connect(_on_frame_changed)
	if not animated_sprite.animation_changed.is_connected(_on_animation_changed):
		animated_sprite.animation_changed.connect(_on_animation_changed)

func _on_hit_landed(_hitbox_node: Node, target_hurtbox: Node) -> void:
	if target_hurtbox.hurtbox_owner.is_in_group("Player") or target_hurtbox.is_in_group("Player_Hurtbox"):
		SoundManager.play_sound(Sound.hit, "SFX")

func _on_hit_taken(attacker_hitbox: Node, _defender_hurtbox: Node) -> void:
	if attacker_hitbox.hitbox_owner and (attacker_hitbox.hitbox_owner.is_in_group("Player") or attacker_hitbox.is_in_group("Player_Hitbox")) and attacker_hitbox.has_method("get_damage"):
		take_damage(attacker_hitbox.get_damage())
		SoundManager.play_sound(Sound.hit, "SFX")

func move(move_direction: int, move_speed: float) -> void:
	velocity.x = move_direction * move_speed
	_update_facing_direction(move_direction)
	move_and_slide()

func _update_facing_direction(face_direction: int) -> void:
	if not is_instance_valid(animated_sprite):
		return

	if face_direction != 0:
		var was_facing_left = animated_sprite.flip_h
		var face_left = face_direction < 0
		
		if was_facing_left != face_left:
			animated_sprite.flip_h = face_left
			
			# Update hitbox positions
			var current_scale = Vector2(-1 if face_left else 1, 1)
			for box in hitboxes:
				box.scale = current_scale  # Set the entire scale vector at once

func _update_animation() -> void:
	var animation_name: StringName = &"Idle"
	
	if not is_on_floor():
		animation_name = &"Jump"
	elif abs(velocity.x) > 0:
		animation_name = &"Run"
	
	animated_sprite.play(animation_name)

func perform_attack() -> void:
	if not can_attack:
		return

	can_attack = false
	attack_timer = attack_cooldown
	SignalBus.attack_started.emit(self)

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target = body
		SignalBus.player_detected.emit(self, body)

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") and body == target:
		SignalBus.player_lost.emit(self, body)
		target = null

func _on_frame_changed() -> void:
	if frame_data_component:
		frame_data_component.update_frame_data()

func _on_animation_changed() -> void:
	if frame_data_component:
		frame_data_component.update_frame_data()

func take_damage(amount: float) -> void:
	super.take_damage(amount)
	if health_manager.get_health() <= 0:
		SignalBus.enemy_died.emit(self)

func die() -> void:
	queue_free()
