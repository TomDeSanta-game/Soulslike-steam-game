extends Area2D

signal lore_collected(lore_id: String)

@export var lore_id: String = "LORE_001"
@export var lore_title: String = "Lore Fragment"
@export var lore_content: String = "Empty lore content"
@export var interaction_distance: float = 100.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var interaction_prompt: Node2D = $InteractionPrompt
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var player_in_range: bool = false
var collected: bool = false
var can_interact: bool = true

func _ready() -> void:
	interaction_prompt.hide()
	# Connect to interaction system
	add_to_group("interactable")
	
	# Set up shader material
	if sprite:
		var material = ShaderMaterial.new()
		material.shader = preload("res://Shaders/Collectibles/lore_fragment.gdshader")
		
		# Set shader parameters
		material.set_shader_parameter("glow_color", Color(1.0, 0.8, 0.4, 1.0))
		material.set_shader_parameter("glow_intensity", 2.0)
		material.set_shader_parameter("pulse_speed", 3.0)
		material.set_shader_parameter("ray_speed", 2.0)
		material.set_shader_parameter("ray_intensity", 1.0)
		material.set_shader_parameter("distortion_strength", 0.02)
		
		sprite.material = material
	
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
	if body.is_in_group("player") and not collected:
		player_in_range = true
		show_interaction_prompt()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
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
	
	# Emit signal with lore data
	lore_collected.emit(lore_id)
	
	# Add to player's collected lore (assuming we have a global lore manager)
	if has_node("/root/LoreManager"):
		var lore_manager = get_node("/root/LoreManager")
		lore_manager.add_lore_entry(lore_id, lore_title, lore_content)
	
	# Queue free after collection
	queue_free()

func get_interaction_text() -> String:
	return "Read Lore"

func get_interaction_position() -> Vector2:
	return global_position 
