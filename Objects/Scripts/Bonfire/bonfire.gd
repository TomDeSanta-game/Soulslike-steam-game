extends StaticBody2D

var is_active: bool = false
var player_in_range: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var light: PointLight2D = $PointLight2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea

func _ready() -> void:
	animated_sprite.play("idle")
	if is_active:
		_activate()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("INTERACT") and player_in_range and not is_active:
		_activate()

func _activate() -> void:
	is_active = true
	animated_sprite.play("active")
	light.energy = 1.0
	SignalBus.bonfire_activated.emit(self)
	SoundManager.play_sound(Sound.bonfire_lit, "SFX")

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_range = true

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_range = false