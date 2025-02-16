extends Node
class_name BoxFlip

@export var sprite: AnimatedSprite2D
@export var box: Node2D

var original_pos: Vector2
var is_initialized: bool = false

func _ready() -> void:
	if not sprite or not box:
		push_error("BoxFlip: Missing sprite or box reference")
		return
		
	original_pos = box.position
	is_initialized = true
	
	if sprite.has_signal("flip_h_changed"):
		sprite.flip_h_changed.connect(_on_sprite_flipped)

func _on_sprite_flipped() -> void:
	if not is_valid():
		return
		
	box.position.x = -original_pos.x if sprite.flip_h else original_pos.x

func _process(_delta: float) -> void:
	if not is_valid():
		return
		
	# Fallback for sprites that don't emit flip_h_changed signal
	box.position.x = -original_pos.x if sprite.flip_h else original_pos.x

func is_valid() -> bool:
	if not is_initialized:
		return false
		
	if not is_instance_valid(sprite) or not is_instance_valid(box):
		queue_free()  # Self-cleanup if references are invalid
		return false
		
	return true 