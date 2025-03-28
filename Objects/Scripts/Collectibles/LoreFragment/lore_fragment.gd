extends Area2D

@export_group("Lore Fragment Properties")
@export var lore_id: String = "LORE_001"
@export var lore_title: String = "Ancient Fragment"
@export var lore_content: String = "A Piece Of Knowledge From The Old Era. Sells For A Really High Price"
@export var interaction_distance: float = 100.0

@export_group("Special Effects")
@export var enables_teleport: bool = false
@export var camera_focus_duration: float = 2.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var interaction_prompt: Node2D = $InteractionPrompt
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var player_in_range: bool = false
var collected: bool = false
var can_interact: bool = true
var has_focused: bool = false
var is_teleporting: bool = false

func _ready() -> void:
	interaction_prompt.hide()
	# Connect to interaction system
	add_to_group("interactable")
	
	# Set up shader material
	if sprite:
		var fragment_shader_material = ShaderMaterial.new()
		fragment_shader_material.shader = preload("res://Shaders/Collectibles/lore_fragment.gdshader")
		
		# Set shader parameters
		fragment_shader_material.set_shader_parameter("glow_color", Color(1.0, 0.8, 0.4, 1.0))
		fragment_shader_material.set_shader_parameter("glow_intensity", 2.0)
		fragment_shader_material.set_shader_parameter("pulse_speed", 3.0)
		fragment_shader_material.set_shader_parameter("ray_speed", 2.0)
		fragment_shader_material.set_shader_parameter("ray_intensity", 1.0)
		fragment_shader_material.set_shader_parameter("distortion_strength", 0.02)
		
		sprite.material = fragment_shader_material
	
	# Connect mouse signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if player_in_range and can_interact and Input.is_action_just_pressed("interact"):
		collect_lore()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not collected and can_interact:
			collect_lore()

func _on_mouse_entered() -> void:
	if not collected:
		interaction_prompt.show()

func _on_mouse_exited() -> void:
	if not player_in_range:
		interaction_prompt.hide()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not collected:
		player_in_range = true
		show_interaction_prompt()
		
		# Handle camera focus if not done yet
		if not has_focused:
			has_focused = true
			_focus_camera(body)

func _focus_camera(player_node: Node2D) -> void:
	if player_node and player_node.camera:
		var original_zoom = player_node.camera.zoom
		var original_position = player_node.camera.position
		
		# Create tween for smooth camera movement
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Zoom in on the lore fragment
		tween.tween_property(player_node.camera, "zoom", Vector2(1.5, 1.5), 0.5)
		tween.tween_property(player_node.camera, "position", global_position - player_node.global_position, 0.5)
		
		# Wait for focus duration then reset
		await get_tree().create_timer(camera_focus_duration).timeout
		
		# Reset camera
		tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(player_node.camera, "zoom", original_zoom, 0.5)
		tween.tween_property(player_node.camera, "position", original_position, 0.5)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_range = false
		hide_interaction_prompt()

func show_interaction_prompt() -> void:
	interaction_prompt.show()

func hide_interaction_prompt() -> void:
	interaction_prompt.hide()

func collect_lore() -> void:
	if collected:
		return
		
	collected = true
	can_interact = false
	hide_interaction_prompt()
	
	Log.info("Collecting lore: {0}".format([lore_id]))
	
	# Add to inventory
	var item_data = {
		"id": lore_id,
		"name": lore_title,
		"type": "lore",
		"texture": sprite.texture,
		"description": lore_content,
		"use_function": "read_lore",
		"quantity": 1,
		"has_been_read": false,
		"unread": true  # Initial state for sales value
	}
	
	# Add to inventory through the Inventory singleton
	if has_node("/root/Inventory"):
		var inventory = get_node("/root/Inventory")
		inventory.add_item(lore_id, item_data)
	
	# Play collection animation
	if animation_player and animation_player.has_animation("collect"):
		animation_player.play("collect")
		await animation_player.animation_finished
	
	# Emit signal with lore data using SignalBus
	# Add a lore_collected signal to SignalBus if needed
	SignalBus.collectible_collected.emit(self)
	
	# Add to player's collected lore (assuming we have a global lore manager)
	if has_node("/root/LoreManager"):
		var lore_manager = get_node("/root/LoreManager")
		lore_manager.add_lore_entry(lore_id, lore_title, lore_content)
	
	# Handle teleportation if enabled
	if enables_teleport:
		Log.info("Teleport is enabled, attempting teleport...")
		await _handle_teleport()
	else:
		Log.info("Teleport is disabled")
	
	# Queue free after collection and potential teleport
	queue_free()

func _handle_teleport() -> void:
	# Find the player
	var player_node = get_tree().get_first_node_in_group("Player")
	if not player_node:
		Log.info("Teleport failed: Player not found")
		return
		
	Log.info("Found player, applying teleport effect...")
	is_teleporting = true
	
	# Apply teleport shader to player
	if player_node.animated_sprite:
		var teleport_shader_material = ShaderMaterial.new()
		var shader = load("res://Shaders/Collectibles/teleport.gdshader")
		if shader:
			Log.info("Shader loaded successfully")
			teleport_shader_material.shader = shader
			
			# Store the original material to restore later
			var original_material = player_node.animated_sprite.material
			player_node.animated_sprite.material = teleport_shader_material
			
			# Set default shader parameters
			teleport_shader_material.set_shader_parameter("flash_color", Color(0.0, 0.8, 1.0, 1.0))  # Bright cyan
			teleport_shader_material.set_shader_parameter("noise_scale", 40.0)  # Increased noise detail
			teleport_shader_material.set_shader_parameter("alpha_threshold", 0.4)
			teleport_shader_material.set_shader_parameter("progress", 0.0)
			teleport_shader_material.set_shader_parameter("time", 0.0)
			
			# Create time update timer
			var time_timer = Timer.new()
			add_child(time_timer)
			time_timer.wait_time = 1.0/60.0  # 60 FPS update
			time_timer.timeout.connect(
				func():
					if is_instance_valid(teleport_shader_material):
						var current_time = teleport_shader_material.get_shader_parameter("time")
						teleport_shader_material.set_shader_parameter("time", fmod(current_time + 0.05, 3.14159))
			)
			time_timer.start()
			
			# Create dramatic camera effects
			if player_node.camera:
				var zoom_tween = create_tween()
				zoom_tween.tween_property(player_node.camera, "zoom", Vector2(1.2, 1.2), 0.3)
				
				var shake_amount = 0.5
				var shake_duration = 0.3
				player_node.camera.shake(5, shake_duration, shake_amount)
			
			# Create teleport effect tween with shorter duration
			var tween = create_tween()
			tween.tween_property(teleport_shader_material, "shader_parameter/progress", 1.0, 0.3)
			
			# Wait briefly then transition
			await get_tree().create_timer(0.25).timeout
			
			# Verify the scene exists before attempting to change to it
			var target_scene = "res://levels/boss_areas/FrostGuardian/frost_guardian_boss_area.tscn"
			if ResourceLoader.exists(target_scene):
				Log.info("Boss area scene found, changing scene...")
				SceneManager.change_scene(target_scene, { "pattern_enter": "scribbles", "pattern_leave": "curtains"})
			else:
				Log.error("Boss area scene not found at path: " + target_scene)
				return
			
			Log.info("Starting teleport animation...")
			await tween.finished
			Log.info("Teleport animation finished")
			
			# Cleanup
			time_timer.queue_free()
			
			# Restore original material
			if is_instance_valid(player_node) and is_instance_valid(player_node.animated_sprite):
				player_node.animated_sprite.material = original_material
		else:
			Log.error("Failed to load teleport shader!")
	else:
		Log.error("Player's animated_sprite not found!")

func get_interaction_text() -> String:
	return "Read Lore"

func get_interaction_position() -> Vector2:
	return global_position 
