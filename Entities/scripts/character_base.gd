class_name CharacterBase
extends CharacterBody2D

@export_group("Character Properties")
@export var initial_health: float = 100.0
@export var initial_vigour: int = 10

@export_group("Movement Properties")
@export var base_run_speed: float = 300.0
@export var base_crouch_speed: float = 150.0
@export var jump_power: float = -200.0

@export_group("Combat Properties")
@export var team: int = 0  # For team-based collision
@export var hitboxes: Array[Node] = []
@export var hurtboxes: Array[Node] = []

var health_system: HealthSystem
var current_speed: float = base_run_speed
var is_invincible: bool = false
var is_in_hit_stun: bool = false


func _ready() -> void:
	_setup_character()
	_setup_combat_system()


func _setup_character() -> void:
	health_system = HealthSystem.new()
	add_child(health_system)
	health_system._health_changed.connect(_on_health_changed)
	health_system._character_died.connect(_on_character_died)

	set_physics_process(true)


func _setup_combat_system() -> void:
	# Setup hitboxes
	for hitbox in hitboxes:
		if not hitbox:
			continue
		hitbox.hitbox_owner = self
		if hitbox.has_signal("hit_landed"):
			hitbox.hit_landed.connect(_on_hit_landed)

	# Setup hurtboxes
	for hurtbox in hurtboxes:
		if not hurtbox:
			continue
		hurtbox.hurtbox_owner = self
		if hurtbox.has_signal("hit_taken"):
			hurtbox.hit_taken.connect(_on_hit_taken)
		if hurtbox.has_signal("invincibility_started"):
			hurtbox.invincibility_started.connect(_on_invincibility_started)
		if hurtbox.has_signal("invincibility_ended"):
			hurtbox.invincibility_ended.connect(_on_invincibility_ended)


func set_vigour(value: int) -> void:
	health_system.set_vigour(value)


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

	health_system.take_damage(amount)


func heal(amount: float) -> void:
	health_system.heal(amount)


func set_hit_stun(duration: float) -> void:
	is_in_hit_stun = true
	await get_tree().create_timer(duration).timeout
	is_in_hit_stun = false


func _on_hit_landed(hurtbox: Node) -> void:
	# Override in child classes to handle hit effects
	pass


func _on_hit_taken(hitbox: Node) -> void:
	# Override in child classes to handle being hit
	pass


func _on_invincibility_started() -> void:
	is_invincible = true


func _on_invincibility_ended() -> void:
	is_invincible = false


func _on_health_changed(new_health: float, max_health: float) -> void:
	SignalBus.health_changed.emit(new_health, max_health)


func _on_character_died() -> void:
	SignalBus.character_died.emit(self)
	die()


# Virtual function to be overridden by child classes
func die() -> void:
	pass
