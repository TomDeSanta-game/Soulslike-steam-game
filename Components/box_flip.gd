extends Node
class_name BoxFlip

@export var sprite: AnimatedSprite2D
@export var box: Node2D

var original_pos: Vector2

func _ready() -> void:
	original_pos = box.position
	if sprite.has_signal("flip_h_changed"):
		sprite.flip_h_changed.connect(_on_sprite_flipped)

func _on_sprite_flipped() -> void:
	box.position.x = -original_pos.x if sprite.flip_h else original_pos.x

func _process(_delta: float) -> void:
	# Fallback for sprites that don't emit flip_h_changed signal
	box.position.x = -original_pos.x if sprite.flip_h else original_pos.x 