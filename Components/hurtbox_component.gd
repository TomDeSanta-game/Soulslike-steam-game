extends Area2D
class_name HurtboxComponent

var hurtbox_owner: Node2D
var active: bool = true
var invincible: bool = false

@onready var invincibility_timer: Timer = Timer.new()

func _ready() -> void:
	add_child(invincibility_timer)
	invincibility_timer.one_shot = true
	invincibility_timer.timeout.connect(_on_invincibility_timer_timeout)
	add_to_group("Hurtbox")
	
	# Set collision layer and mask using C_Layers constants
	collision_layer = C_Layers.LAYER_HURTBOX
	collision_mask = C_Layers.MASK_HURTBOX

func take_hit(hitbox: Node) -> void:
	if not active or invincible:
		return

	SignalBus.hit_taken.emit(hitbox, self)  # Use global signal only
	
	if not hurtbox_owner or not hurtbox_owner.has_method("take_damage"):
		Log.info("HurtboxComponent: Owner {0} cannot take damage".format([hurtbox_owner.name if hurtbox_owner else "null"]))
		return
	
	var damage_amount: float = 0.0
	
	# Try to get damage value in order of priority
	if hitbox.has_method("get_damage"):
		damage_amount = hitbox.get_damage()
		Log.info("HurtboxComponent: Got damage {0} from get_damage()".format([damage_amount]))
	elif hitbox is HitboxComponent:
		damage_amount = hitbox.damage
		Log.info("HurtboxComponent: Got damage {0} from HitboxComponent.damage".format([damage_amount]))
	elif "damage" in hitbox:
		damage_amount = hitbox.damage
		Log.info("HurtboxComponent: Got damage {0} from hitbox.damage property".format([damage_amount]))
	else:
		Log.info("HurtboxComponent: Could not get damage value from hitbox")
		return
	
	Log.info("HurtboxComponent: Applying damage {0} to {1}".format([damage_amount, hurtbox_owner.name]))
	hurtbox_owner.take_damage(damage_amount)

func start_invincibility(duration: float = 0.5) -> void:
	invincible = true
	SignalBus.invincibility_started.emit(hurtbox_owner)  # Use global signal only
	invincibility_timer.start(duration)

func end_invincibility() -> void:
	invincible = false
	invincibility_timer.stop()
	SignalBus.invincibility_ended.emit(hurtbox_owner)  # Use global signal only

func _on_invincibility_timer_timeout() -> void:
	invincible = false
	SignalBus.invincibility_ended.emit(hurtbox_owner)  # Use global signal only 