extends Node2D
class_name FrameDataComponent

# Core node references
@export var sprite: AnimatedSprite2D
@export var hitbox: HitboxComponent
@export var hurtbox: HurtboxComponent
@export var frame_data_resource: Resource
@export var debug_draw: bool = false  # Enable to see hitbox/hurtbox visualization

const DEBUG_COLORS = {
	"HITBOX": Color(1, 0, 0, 0.5),  # Red with 50% transparency
	"HURTBOX": Color(0, 1, 0, 0.5)   # Green with 50% transparency
}

var _initialized: bool = false
var current_frame_data: Dictionary = {}
var attack_frames: Dictionary = {}

func _ready() -> void:
	if not sprite:
		push_error("FrameDataComponent: No sprite assigned")
		return

	# Initial frame data update
	update_frame_data()


func _draw() -> void:
	if not debug_draw:
		return
		
	# Draw hitbox
	if hitbox and hitbox.active:
		var hitbox_shape = hitbox.get_node("CollisionShape2D")
		if hitbox_shape and hitbox_shape.shape:
			_draw_collision_shape(hitbox_shape, DEBUG_COLORS.HITBOX)
	
	# Draw hurtbox
	if hurtbox and hurtbox.active:
		var hurtbox_shape = hurtbox.get_node("CollisionShape2D")
		if hurtbox_shape and hurtbox_shape.shape:
			_draw_collision_shape(hurtbox_shape, DEBUG_COLORS.HURTBOX)


func _draw_collision_shape(shape_node: CollisionShape2D, color: Color) -> void:
	var shape = shape_node.shape
	var transform = shape_node.global_transform
	
	if shape is RectangleShape2D:
		var rect = Rect2(-shape.extents, shape.extents * 2)
		draw_rect(rect, color)
	elif shape is CircleShape2D:
		draw_circle(Vector2.ZERO, shape.radius, color)
	elif shape is CapsuleShape2D:
		var height = shape.height
		var radius = shape.radius
		# Draw the capsule body
		var rect = Rect2(Vector2(-radius, -height/2), Vector2(radius * 2, height))
		draw_rect(rect, color)
		# Draw the rounded ends
		draw_circle(Vector2(0, -height/2), radius, color)
		draw_circle(Vector2(0, height/2), radius, color)


func update_frame_data() -> void:
	if not sprite:
		return

	var animation = sprite.animation
	var frame = sprite.frame

	# Get frame data for current animation frame
	current_frame_data = _get_frame_data(animation, frame)

	# Update hitbox and hurtbox based on frame data
	_update_boxes()
	
	# Request redraw for debug visualization
	if debug_draw:
		queue_redraw()


func _update_boxes() -> void:
	# Update hitbox
	if hitbox and current_frame_data.has("hitboxes"):
		for box_name in current_frame_data.hitboxes:
			var box_data = current_frame_data.hitboxes[box_name]
			hitbox.position = box_data.position
			# Don't deactivate the base hitbox, just update its properties
			if not hitbox.active:
				hitbox.active = true

	# Update hurtbox
	if hurtbox and current_frame_data.has("hurtboxes"):
		for box_name in current_frame_data.hurtboxes:
			var box_data = current_frame_data.hurtboxes[box_name]
			hurtbox.position = box_data.position
			# Don't deactivate the base hurtbox, just update its properties
			if not hurtbox.active:
				hurtbox.active = true


func clear_active_boxes() -> void:
	# Instead of deactivating boxes, reset their positions
	if hitbox:
		hitbox.position = Vector2.ZERO
	if hurtbox:
		hurtbox.position = Vector2.ZERO


func _check_initialization() -> void:
	_initialized = sprite != null and hitbox != null and hurtbox != null
	if not _initialized:
		return


func _get_frame_data(animation: String, frame: int) -> Dictionary:
	if frame_data_resource and frame_data_resource.has_method("get_frame_data"):
		return frame_data_resource.get_frame_data(animation, frame)
	return {}
