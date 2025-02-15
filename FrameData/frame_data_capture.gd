extends Node2D
class_name FrameDataCapture

@export var target_sprite: AnimatedSprite2D
@export var frame_data_resource: FrameDataResource  # Save data directly to FrameDataResource
@export var hitbox_color: Color = Color(1, 0, 0, 0.5)
@export var hurtbox_color: Color = Color(0, 0, 1, 0.5)
@export var recording: bool = false
@export var auto_save: bool = true
@export var capture_interval: float = 1.0 / 60.0  # Capture every frame at 60fps

var current_frame_data: FrameData
var capture_areas: Array[CollisionShape2D] = []
var recording_animation: String = ""
var capture_timer: float = 0.0


func _ready() -> void:
	if target_sprite:
		target_sprite.frame_changed.connect(_on_frame_changed)
		target_sprite.animation_changed.connect(_on_animation_changed)


func _process(delta: float) -> void:
	if recording:
		capture_timer += delta
		if capture_timer >= capture_interval:
			capture_timer = 0.0
			capture_current_frame()
			queue_redraw()


func start_recording(animation_name: String) -> void:
	recording = true
	recording_animation = animation_name
	frame_data_resource.animation_name = animation_name
	frame_data_resource.frame_data.clear()
	frame_data_resource.frame_rate = 1.0 / capture_interval
	capture_timer = 0.0


func stop_recording() -> void:
	recording = false
	if auto_save:
		save_frame_data()


func save_frame_data() -> void:
	var save_path = "res://frame_data/" + recording_animation + "_frames.tres"
	if ResourceSaver.save(frame_data_resource, save_path) == OK:
		print("Frame data saved successfully!")


func _on_animation_changed() -> void:
	if recording:
		start_recording(target_sprite.animation)


func _on_frame_changed() -> void:
	if recording:
		capture_current_frame()
		queue_redraw()


func capture_current_frame() -> void:
	var frame_data = FrameData.new()
	frame_data.frame_number = target_sprite.frame

	# Capture hitboxes and hurtboxes
	for area in capture_areas:
		var shape = area.shape
		if shape is RectangleShape2D:
			var global_pos = area.global_position
			var size = shape.size

			if area.is_in_group("hitbox"):
				frame_data.hitboxes[area.name] = {"position": global_pos, "size": size}
			elif area.is_in_group("hurtbox"):
				frame_data.hurtboxes[area.name] = {"position": global_pos, "size": size}

	# Update frame data in resource
	frame_data_resource.frame_data.append(frame_data)

	current_frame_data = frame_data


func _draw() -> void:
	if not recording or not current_frame_data:
		return

	# Draw debug visualization
	for hitbox in current_frame_data.hitboxes.values():
		var pos = hitbox["position"]
		var size = hitbox["size"]
		draw_rect(Rect2(pos - size / 2, size), hitbox_color)

	for hurtbox in current_frame_data.hurtboxes.values():
		var pos = hurtbox["position"]
		var size = hurtbox["size"]
		draw_rect(Rect2(pos - size / 2, size), hurtbox_color)


func register_capture_area(area: CollisionShape2D) -> void:
	if not capture_areas.has(area):
		capture_areas.append(area)


func unregister_capture_area(area: CollisionShape2D) -> void:
	capture_areas.erase(area)
