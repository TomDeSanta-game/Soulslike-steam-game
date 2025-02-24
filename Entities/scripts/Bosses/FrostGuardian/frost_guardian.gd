# Version 1.0.0
extends BossBase
class_name FrostGuardian

@export_group("Frost Guardian Properties")
@export var ice_damage_multiplier: float = 1.2
@export var frost_effect_duration: float = 3.0

var is_attacking: bool = false
var attack_frame: int = 0

func _ready() -> void:
	super._ready()
	
	# Set Frost Guardian specific properties
	boss_name = "Frost Guardian"
	attack_damage *= ice_damage_multiplier
	
	# Configure hitbox and hurtbox positions
	if boss_hitbox and boss_hitbox.has_method("set_position"):
		boss_hitbox.position = Vector2(-50, 5)
		
	if boss_hurtbox and boss_hurtbox.has_method("set_position"):
		boss_hurtbox.position = Vector2(0, 2.5)
		boss_hurtbox.active = true  # Always active

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if is_attacking:
		_handle_attack_frames()

func _handle_attack_frames() -> void:
	if not animated_sprite or not boss_hitbox:
		return
		
	attack_frame = animated_sprite.frame
	
	# Activate hitbox during specific attack frames
	if attack_frame in [6, 7, 8]:
		boss_hitbox.active = true
	else:
		boss_hitbox.active = false

func _on_animation_changed() -> void:
	super._on_animation_changed()
	
	if not animated_sprite:
		return
		
	is_attacking = animated_sprite.animation == "Attack"
	if not is_attacking:
		boss_hitbox.active = false

func _execute_attack_pattern(attack_name: String) -> void:
	match attack_name:
		"frost_slash":
			_perform_frost_slash()
		"ice_storm":
			_perform_ice_storm()
		"frozen_ground":
			_perform_frozen_ground()

func _perform_frost_slash() -> void:
	if not animated_sprite:
		return
		
	animated_sprite.play("Attack")
	# Additional frost slash specific logic here

func _perform_ice_storm() -> void:
	# Implement ice storm attack pattern
	pass

func _perform_frozen_ground() -> void:
	# Implement frozen ground attack pattern
	pass

func _on_hit_landed(target_hurtbox: Node) -> void:
	super._on_hit_landed(target_hurtbox)
	
	# Apply frost effect to the target
	if target_hurtbox.hurtbox_owner.has_method("apply_frost_effect"):
		target_hurtbox.hurtbox_owner.apply_frost_effect(frost_effect_duration)

func _on_phase_transition() -> void:
	match current_phase:
		1:  # Phase 2 transition (70% health)
			attack_damage *= 1.2
			attack_cooldown *= 0.9
		2:  # Phase 3 transition (30% health)
			attack_damage *= 1.3
			attack_cooldown *= 0.8
			frost_effect_duration *= 1.5
