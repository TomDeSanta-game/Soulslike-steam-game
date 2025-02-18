class_name ComponentTypes
extends Node

class HitboxData:
	var damage: float
	var knockback_force: float
	var hit_stun_duration: float
	var active: bool
	var hitbox_owner: Node
	
	func _init(p_damage: float = 10.0, p_knockback: float = 200.0, p_stun: float = 0.2) -> void:
		damage = p_damage
		knockback_force = p_knockback
		hit_stun_duration = p_stun
		active = true

class HurtboxData:
	var active: bool
	var invincible: bool
	var hurtbox_owner: Node
	
	func _init() -> void:
		active = true
		invincible = false

static func create_hitbox_data(damage: float = 10.0, knockback: float = 200.0, stun: float = 0.2) -> HitboxData:
	return HitboxData.new(damage, knockback, stun)

static func create_hurtbox_data() -> HurtboxData:
	return HurtboxData.new() 