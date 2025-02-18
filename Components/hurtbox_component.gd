extends Area2D
class_name HurtboxComponent

signal hit_taken(hitbox: Node)
signal invincibility_started
signal invincibility_ended

var hurtbox_owner: Node2D
var active: bool = true
var invincible: bool = false

@onready var invincibility_timer: Timer = Timer.new()

func _ready() -> void:
	add_child(invincibility_timer)
	invincibility_timer.one_shot = true
	invincibility_timer.timeout.connect(_on_invincibility_timer_timeout)
	add_to_group("Hurtbox")
	
	# Set collision layer and mask
	collision_layer = 4  # Layer 4 for hurtboxes
	collision_mask = 2   # Layer 2 for hitboxes

func take_hit(hitbox: Node) -> void:
	if not active or invincible:
		return

	hit_taken.emit(hitbox)  # Emit local signal
	SignalBus.hit_taken.emit(hitbox, self)  # Emit global signal
	
	if hurtbox_owner and hurtbox_owner.has_method("take_damage"):
		if hitbox.has_method("get_damage"):
			hurtbox_owner.take_damage(hitbox.get_damage())
		elif hitbox.has_property("damage"):
			hurtbox_owner.take_damage(hitbox.damage)

func start_invincibility(duration: float = 0.5) -> void:
	invincible = true
	invincibility_started.emit()  # Emit local signal
	SignalBus.invincibility_started.emit(hurtbox_owner)  # Emit global signal
	invincibility_timer.start(duration)

func _on_invincibility_timer_timeout() -> void:
	invincible = false
	invincibility_ended.emit()  # Emit local signal
	SignalBus.invincibility_ended.emit(hurtbox_owner)  # Emit global signal 