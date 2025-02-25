extends Node2D
class_name FrameDataComponent

# Core node references
@export var sprite: AnimatedSprite2D
@export var hitbox: HitboxComponent
@export var hurtbox: HurtboxComponent
@export var debug_draw: bool = false

const DEBUG_COLORS = {
	"HITBOX": Color(1, 0, 0, 0.5),  # Red with 50% transparency
	"HURTBOX": Color(0, 1, 0, 0.5)   # Green with 50% transparency
}

# Predefined positions for different animations and their active frames
const ANIMATION_DATA = {
	"Attack": {
		"frames": [1, 2],
		"positions": {
			"hitbox": Vector2(0, 0),
			"hurtbox": Vector2(0, 5)
		}
	},
	"Run_Attack": {
		"frames": [2, 3, 4],
		"positions": {
			"hitbox": Vector2(6.5, 0),
			"hurtbox": Vector2(0, 5)
		}
	}
}

func _ready() -> void:
	if not sprite:
		push_error("FrameDataComponent: No sprite assigned")
		return

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
	var collision_shape = shape_node.shape
	
	if collision_shape is RectangleShape2D:
		var rect = Rect2(-collision_shape.extents, collision_shape.extents * 2)
		draw_rect(rect, color)
	elif collision_shape is CircleShape2D:
		draw_circle(Vector2.ZERO, collision_shape.radius, color)
	elif collision_shape is CapsuleShape2D:
		var capsule_height = collision_shape.height
		var capsule_radius = collision_shape.radius
		var rect = Rect2(Vector2(-capsule_radius, -capsule_height/2), Vector2(capsule_radius * 2, capsule_height))
		draw_rect(rect, color)
		draw_circle(Vector2(0, -capsule_height/2), capsule_radius, color)
		draw_circle(Vector2(0, capsule_height/2), capsule_radius, color)

func update_frame_data() -> void:
	if not sprite:
		return

	var animation = sprite.animation
	var current_frame = sprite.frame
	
	# Update positions based on animation and frame
	if ANIMATION_DATA.has(animation):
		var data = ANIMATION_DATA[animation]
		if data.frames.has(current_frame):
			if hitbox and data.positions.has("hitbox"):
				hitbox.position = data.positions.hitbox
			if hurtbox and data.positions.has("hurtbox"):
				hurtbox.position = data.positions.hurtbox
		else:
			clear_active_boxes()
	else:
		clear_active_boxes()
	
	if debug_draw:
		queue_redraw()

func clear_active_boxes() -> void:
	if hitbox:
		hitbox.position = Vector2.ZERO
	if hurtbox:
		hurtbox.position = Vector2.ZERO
