# Version 1.0.0
extends CharacterBase
class_name BossBase

@export_group("Boss Properties")
@export var boss_name: String = "Boss"
@export var attack_damage: float = 25.0
@export var attack_range: float = 100.0
@export var attack_cooldown: float = 1.5
@export var detection_range: float = 300.0
@export var max_health: float = 500.0
@export var phase_health_thresholds: Array[float] = [0.7, 0.3]  # Trigger phase changes at 70% and 30% health

@export_group("Boss Combat")
@export var attack_patterns: Array[Dictionary] = []
@export var current_phase: int = 0
@export var is_phase_transitioning: bool = false

@onready var boss_hitbox: Node = %HitBox
@onready var boss_hurtbox: Node = %HurtBox
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea

var current_health: float
var current_direction: int = 1
var target: Node2D = null
var can_attack: bool = true
var attack_timer: float = 0.0
var current_attack_pattern: Dictionary = {}

const MOVEMENT_SPEEDS = {
	"WALK": 200.0,
	"RUN": 300.0,
	"DASH": 500.0,
}

@onready var frame_data_component: FrameDataComponent = $FrameDataComponent

func _ready() -> void:
	super._ready()
	_setup_boss()
	
	# Initialize health
	current_health = max_health
	
	# Set team to 2 (bosses)
	team = 2
	
	# Initialize health system with boss-specific settings
	health_system = HealthSystem.new()
	add_child(health_system)
	health_system.set_vigour(initial_vigour)
	
	# Set collision layers/masks for boss
	collision_layer = C_Layers.LAYER_BOSS
	collision_mask = C_Layers.MASK_BOSS
	
	if boss_hitbox:
		boss_hitbox.hitbox_owner = self
		boss_hitbox.collision_layer = C_Layers.LAYER_HITBOX
		boss_hitbox.collision_mask = C_Layers.MASK_HITBOX
	
	if boss_hurtbox:
		boss_hurtbox.hurtbox_owner = self
		boss_hurtbox.collision_layer = C_Layers.LAYER_HURTBOX
		boss_hurtbox.collision_mask = C_Layers.MASK_HURTBOX

func _setup_boss() -> void:
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	if boss_hitbox:
		boss_hitbox.hitbox_owner = self
		boss_hitbox.damage = attack_damage
	
	if boss_hurtbox:
		boss_hurtbox.hurtbox_owner = self
	
	_setup_combat_components()
	_setup_frame_data()

func _physics_process(delta: float) -> void:
	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			can_attack = true
	
	_check_phase_transition()
	_update_boss_behavior(delta)

func _setup_combat_components() -> void:
	if boss_hitbox:
		boss_hitbox.hitbox_owner = self
		boss_hitbox.damage = attack_damage
		boss_hitbox.knockback_force = 300.0
		boss_hitbox.hit_stun_duration = 0.3
		if boss_hitbox.has_signal("hit_landed"):
			boss_hitbox.hit_landed.connect(_on_hit_landed)
	
	if boss_hurtbox:
		boss_hurtbox.hurtbox_owner = self
		if boss_hurtbox.has_signal("hit_taken"):
			boss_hurtbox.hit_taken.connect(_on_hit_taken)
	
	add_to_group("Boss")

func _check_phase_transition() -> void:
	if is_phase_transitioning:
		return
	
	var health_percentage = current_health / max_health
	for i in range(phase_health_thresholds.size()):
		if health_percentage <= phase_health_thresholds[i] and current_phase == i:
			_transition_to_next_phase()
			break

func _transition_to_next_phase() -> void:
	is_phase_transitioning = true
	current_phase += 1
	
	# Emit signal for phase transition
	SignalBus.boss_phase_changed.emit(self, current_phase)
	
	# Override in child class to implement specific phase transition behavior
	_on_phase_transition()
	
	is_phase_transitioning = false

func _on_phase_transition() -> void:
	# Override in child class to implement specific phase transition behavior
	pass

func _update_boss_behavior(delta: float) -> void:
	# Override in child class to implement specific boss behavior
	pass

func perform_attack(attack_name: String) -> void:
	if not can_attack:
		return
	
	can_attack = false
	attack_timer = attack_cooldown
	
	# Override in child class to implement specific attack patterns
	_execute_attack_pattern(attack_name)
	SignalBus.boss_attack_started.emit(self, attack_name)

func _execute_attack_pattern(attack_name: String) -> void:
	# Override in child class to implement specific attack patterns
	pass

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
				box.scale = current_scale

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target = body
		SignalBus.player_detected.emit(self, body)

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") and body == target:
		SignalBus.player_lost.emit(self, body)
		target = null

func _on_hit_landed(target_hurtbox: Node) -> void:
	if target_hurtbox.hurtbox_owner.is_in_group("Player") or target_hurtbox.is_in_group("Player_Hurtbox"):
		SoundManager.play_sound(Sound.boss_hit, "SFX")

func _on_hit_taken(attacker_hitbox: Node) -> void:
	if attacker_hitbox.hitbox_owner and (attacker_hitbox.hitbox_owner.is_in_group("Player") or attacker_hitbox.is_in_group("Player_Hitbox")):
		take_damage(attacker_hitbox.damage)
		SignalBus.boss_damaged.emit(self, current_health, max_health)

func take_damage(amount: float) -> void:
	super.take_damage(amount)
	current_health = health_system.get_health()

func die() -> void:
	SignalBus.boss_defeated.emit(self)
	queue_free()

func _setup_frame_data() -> void:
	var frame_data_component = get_node_or_null("FrameDataComponent")
	if not frame_data_component:
		return
	
	if not animated_sprite:
		push_error("AnimatedSprite2D not found in boss")
		return
	
	if boss_hitbox:
		frame_data_component.hitbox = boss_hitbox
		frame_data_component.update_frame_data()
	
	if boss_hurtbox:
		frame_data_component.hurtbox = boss_hurtbox
	
	if not animated_sprite.frame_changed.is_connected(_on_frame_changed):
		animated_sprite.frame_changed.connect(_on_frame_changed)
	if not animated_sprite.animation_changed.is_connected(_on_animation_changed):
		animated_sprite.animation_changed.connect(_on_animation_changed)

func _on_frame_changed() -> void:
	var frame_data_component = get_node_or_null("FrameDataComponent")
	if frame_data_component:
		frame_data_component.update_frame_data()

func _on_animation_changed() -> void:
	var frame_data_component = get_node_or_null("FrameDataComponent")
	if frame_data_component:
		frame_data_component.update_frame_data()
