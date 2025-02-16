extends Area2D
class_name HurtboxComponent

signal hit_taken(hitbox: HitboxComponent)
signal invincibility_started
signal invincibility_ended

# Hurtbox properties
@export var invincible: bool = false
@export var invincibility_duration: float = 0.2  # Reduced from 0.5 to 0.2 seconds
@export var active: bool = true

# Owner reference (usually the character that can be hurt)
var hurtbox_owner: Node

# Invincibility timer
var _invincibility_timer: Timer

func _ready() -> void:
	# Set collision layer and mask
	collision_layer = 4  # Layer 3 for hurtboxes
	collision_mask = 2   # Layer 2 for hitboxes
	
	# Get owner reference
	hurtbox_owner = get_parent()
	
	# Setup invincibility timer
	_invincibility_timer = Timer.new()
	_invincibility_timer.one_shot = true
	_invincibility_timer.timeout.connect(_on_invincibility_timer_timeout)
	add_child(_invincibility_timer)
	
	# Ensure hurtbox is active by default
	active = true
	show()


func take_hit(hitbox: HitboxComponent, knockback_direction: Vector2) -> bool:
	# Check if we can be hit
	if invincible or not active:
		return false
	
	# Apply damage if owner has health system
	if hurtbox_owner.has_method("take_damage"):
		hurtbox_owner.take_damage(hitbox.damage)
	
	# Apply knockback if owner is a physics body
	if hurtbox_owner is CharacterBody2D:
		_apply_knockback(hitbox, knockback_direction)
	
	# Apply hit stun if owner has a state machine
	if hurtbox_owner.has_method("set_hit_stun"):
		hurtbox_owner.set_hit_stun(hitbox.hit_stun_duration)
	
	# Start invincibility
	start_invincibility(invincibility_duration)
	
	# Emit hit signal
	hit_taken.emit(hitbox)
	
	return true


func start_invincibility(duration: float = 0.2) -> void:
	if not invincible:
		invincible = true
		invincibility_started.emit()
		_invincibility_timer.start(duration)


func _on_invincibility_timer_timeout() -> void:
	invincible = false
	invincibility_ended.emit()


func _apply_knockback(hitbox: HitboxComponent, direction: Vector2) -> void:
	if hurtbox_owner is CharacterBody2D:
		var knockback = direction * hitbox.knockback_force
		hurtbox_owner.velocity = knockback 