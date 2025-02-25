class_name CharacterBase
extends CharacterBody2D

const CharacterHealthManager = preload("res://Globals/character_health_manager.gd")

@export_group("Character Properties")
@warning_ignore("unused_private_class_variable")
@export var initial_health: float = 100.0
@export var initial_vigour: int = 10

@export_group("Movement Properties")
@export var base_run_speed: float = 100.0
@export var base_crouch_speed: float = 150.0
@export var jump_power: float = -200.0

@export_group("Combat Properties")
@warning_ignore("unused_private_class_variable")
@export var team: int = 0  # For team-based collision
@warning_ignore("unused_private_class_variable")
@export var hitboxes: Array[Node] = []
@warning_ignore("unused_private_class_variable")
@export var hurtboxes: Array[Node] = []

var health_manager: Node
@warning_ignore("unused_private_class_variable")
var current_speed: float = base_run_speed
@warning_ignore("unused_private_class_variable")
var is_invincible: bool = false
@warning_ignore("unused_private_class_variable")
var is_in_hit_stun: bool = false


func _ready() -> void:
	_setup_character()
	_setup_combat_system()


func _setup_character() -> void:
	health_manager = CharacterHealthManager.new()
	add_child(health_manager)
	SignalBus.health_changed.connect(_on_health_changed)
	SignalBus.character_died.connect(_on_character_died)
	health_manager.set_vigour(initial_vigour)

	set_physics_process(true)


func _setup_combat_system() -> void:
	# Setup hitboxes
	for hitbox in hitboxes:
		if not hitbox:
			continue
		hitbox.hitbox_owner = self

	# Setup hurtboxes
	for hurtbox in hurtboxes:
		if not hurtbox:
			continue
		hurtbox.hurtbox_owner = self
	
	# Connect to SignalBus signals
	if !SignalBus.hit_landed.is_connected(_on_hit_landed):
		SignalBus.hit_landed.connect(_on_hit_landed)
	if !SignalBus.hit_taken.is_connected(_on_hit_taken):
		SignalBus.hit_taken.connect(_on_hit_taken)
	if !SignalBus.invincibility_started.is_connected(_on_invincibility_started):
		SignalBus.invincibility_started.connect(_on_invincibility_started)
	if !SignalBus.invincibility_ended.is_connected(_on_invincibility_ended):
		SignalBus.invincibility_ended.connect(_on_invincibility_ended)


func set_vigour(value: int) -> void:
	health_manager.set_vigour(value)


func set_jump_power(value: float) -> void:
	jump_power = value


func get_vigour() -> int:
	return initial_vigour


func get_jump_power() -> float:
	return jump_power


func get_movement_speed(movement_type: String) -> float:
	match movement_type:
		"run":
			return base_run_speed
		"crouch":
			return base_crouch_speed
		_:
			return 0.0


func take_damage(amount: float) -> void:
	if is_invincible:
		return

	health_manager.take_damage(amount)


func heal(amount: float) -> void:
	health_manager.heal(amount)


func get_health() -> float:
	return health_manager.get_health()


func get_max_health() -> float:
	return health_manager.get_max_health()


func get_health_percentage() -> float:
	return health_manager.get_health_percentage()


func set_hit_stun(duration: float) -> void:
	is_in_hit_stun = true
	await get_tree().create_timer(duration).timeout
	is_in_hit_stun = false


@warning_ignore("unused_parameter")
func _on_hit_landed(hitbox: Node, hurtbox: Node) -> void:
	# Override in child classes to handle hit effects
	pass


@warning_ignore("unused_parameter")
func _on_hit_taken(hitbox: Node, hurtbox: Node) -> void:
	# Override in child classes to handle being hit
	pass


func _on_invincibility_started(_entity: Node) -> void:
	is_invincible = true


func _on_invincibility_ended(_entity: Node) -> void:
	is_invincible = false


@warning_ignore("unused_parameter")
func _on_health_changed(new_health: float, max_health: float) -> void:
	# Do not re-emit the signal to avoid infinite recursion
	pass


func _on_character_died() -> void:
	# Do not re-emit the signal to avoid infinite recursion
	die()


# Virtual function to be overridden by child classes
func die() -> void:
	pass
