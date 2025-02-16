class_name CharacterBase
extends CharacterBody2D

signal health_changed(new_health: float, max_health: float)
signal character_died

@export_group("Character Properties")
@export var initial_health: float = 100.0
@export var initial_vigour: int = 10

@export_group("Movement Properties")
@export var base_run_speed: float = 300.0
@export var base_crouch_speed: float = 150.0
@export var jump_power: float = -200.0

@export_group("Combat Properties")
@export var team: int = 0  # For team-based collision
@export var hitboxes: Array[HitboxComponent] = []
@export var hurtboxes: Array[HurtboxComponent] = []

@onready var health_system = preload("res://Globals/character_health_manager.gd").new()

var current_speed: float = base_run_speed
var is_invincible: bool = false
var is_in_hit_stun: bool = false


func _ready() -> void:
	_setup_character()
	_setup_combat_system()


func _setup_character() -> void:
	# Initialize health system
	add_child(health_system)
	health_system._health_changed.connect(_on_health_changed)
	health_system._character_died.connect(_on_character_died)
	health_system.set_vigour(initial_vigour)

	set_physics_process(true)


func _setup_combat_system() -> void:
	# Setup hitboxes
	for hitbox in hitboxes:
		if not hitbox:
			continue
		hitbox.hitbox_owner = self
		hitbox.hit_landed.connect(_on_hit_landed)
	
	# Setup hurtboxes
	for hurtbox in hurtboxes:
		if not hurtbox:
			continue
		hurtbox.hurtbox_owner = self
		hurtbox.hit_taken.connect(_on_hit_taken)
		hurtbox.invincibility_started.connect(_on_invincibility_started)
		hurtbox.invincibility_ended.connect(_on_invincibility_ended)


# Add this function to allow setting vigor
func set_vigour(value: int) -> void:
	initial_vigour = value
	if health_system:
		health_system.set_vigour(value)


# Add this function to get current vigor
func get_vigour() -> int:
	return initial_vigour


func get_movement_speed(movement_type: String) -> float:
	match movement_type:
		"run":
			return base_run_speed
		"crouch":
			return base_crouch_speed
		_:
			return 0.0


# Combat System Functions
func take_damage(amount: float) -> void:
	if is_invincible:
		return
		
	if health_system:
		health_system.take_damage(amount)


func heal(amount: float) -> void:
	if health_system:
		health_system.heal(amount)


func set_hit_stun(duration: float) -> void:
	is_in_hit_stun = true
	await get_tree().create_timer(duration).timeout
	is_in_hit_stun = false

@warning_ignore("unused_parameter")
func _on_hit_landed(hurtbox: HurtboxComponent) -> void:
	# Override in child classes to handle hit effects
	pass

@warning_ignore("unused_parameter")
func _on_hit_taken(hitbox: HitboxComponent) -> void:
	# Override in child classes to handle being hit
	pass


func _on_invincibility_started() -> void:
	is_invincible = true


func _on_invincibility_ended() -> void:
	is_invincible = false


func _on_health_changed(new_health: float, max_health: float) -> void:
	health_changed.emit(new_health, max_health)


func _on_character_died() -> void:
	character_died.emit()
	die()


# Virtual function to be overridden by child classes
func die() -> void:
	pass
