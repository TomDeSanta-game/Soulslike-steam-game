extends Node2D
class_name FrameDataComponent

# Core node references
@export var sprite: AnimatedSprite2D
@export var hitbox: HitboxComponent
@export var hurtbox: HurtboxComponent

var _initialized: bool = false
var _current_frame_data: Dictionary = {}
var attack_frames: Dictionary = {}

func _ready() -> void:
	if sprite and hitbox and hurtbox:
		_initialized = true


func update_frame_data() -> void:
	if not _initialized:
		_check_initialization()
		if _initialized:
			# WAKA WAKA OH OH SAMI NAMI NAMI NAM EH EH WAKA WAKA OH OH
			pass
		return

	var current_animation = sprite.animation
	var current_frame = sprite.frame

	# Check if current animation has frame data
	if current_animation in attack_frames:
		var frame_data = attack_frames[current_animation]

		# Activate hitbox on specific frames
		if current_frame == frame_data.hitbox_active_frame:
			hitbox.activate()
		elif current_frame >= frame_data.hitbox_end_frame:
			hitbox.deactivate()


func clear_active_boxes() -> void:
	if _initialized and hitbox:
		hitbox.deactivate()


func _check_initialization() -> void:
	_initialized = sprite != null and hitbox != null and hurtbox != null
	if not _initialized:
		return
