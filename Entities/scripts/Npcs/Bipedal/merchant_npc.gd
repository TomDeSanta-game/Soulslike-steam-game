extends NpcBase

@onready var interact_button: Button = $InteractButton
@onready var merchant_menu_scene: PackedScene = preload("res://UI/Scenes/MerchantMenu.tscn")
var merchant_menu: MerchantMenu = null

var merchant_name: String = "Merchant#1"
var merchant_inventory: Dictionary = {
	"celestial_tear": {
		"id": "celestial_tear",
		"name": "Celestial Tear",
		"description": "A divine crystallized tear from the heavens, radiating pure celestial energy. Restores full health and stamina when used.",
		"price": 50000,
		"texture": load("res://assets/Sprite-0003.png"),
		"use_function": "use_celestial_tear",
		"quantity": 5
	},
	"LORE_001": {
		"id": "LORE_001",
		"name": "Ancient Fragment",
		"description": "A Piece Of Knowledge From The Old Era",
		"price": 100000,
		"type": "lore",
		"texture": load("res://assets/cover.png"),
		"use_function": "read_lore",
		"has_been_read": false,
		"unread": true,
		"quantity": 1
	}
}

func _ready() -> void:
	super._ready()
	
	# Set collision layers and masks
	collision_layer = C_Layers.LAYER_NPC
	collision_mask = C_Layers.LAYER_WORLD
	
	# Set ChatBoxArea collision properties
	if $ChatBoxArea:
		$ChatBoxArea.collision_layer = 0  # Don't need a layer since we're only detecting
		$ChatBoxArea.collision_mask = C_Layers.LAYER_PLAYER
	
	# Setup interact button
	interact_button.visible = false
	interact_button.text = "SHOP"
	interact_button.position = Vector2(-50, -80)  # Position above the merchant
	interact_button.size = Vector2(100, 30)      # Set a fixed size
	
	# Make sure button is in front and clickable
	interact_button.z_index = 100
	interact_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND  # Show hand cursor on hover
	
	# Connect area signals
	if $ChatBoxArea:
		if !$ChatBoxArea.body_entered.is_connected(_on_chat_box_area_body_entered):
			$ChatBoxArea.body_entered.connect(_on_chat_box_area_body_entered)
		if !$ChatBoxArea.body_exited.is_connected(_on_chat_box_area_body_exited):
			$ChatBoxArea.body_exited.connect(_on_chat_box_area_body_exited)
	
	# Initialize merchant menu
	call_deferred("_setup_merchant_menu")

func _setup_merchant_menu() -> void:
	# Create a new UI layer if needed
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # Set to a high layer to ensure it's on top
	add_child(canvas_layer)
	
	# Initialize merchant menu
	merchant_menu = merchant_menu_scene.instantiate()
	canvas_layer.add_child(merchant_menu)
	merchant_menu.visible = false
	merchant_menu.set_merchant_name(merchant_name)
	merchant_menu.set_merchant_inventory(merchant_inventory)

func _on_chat_box_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		# Show the button with a nice fade-in effect
		interact_button.modulate.a = 0
		interact_button.visible = true
		var tween = create_tween()
		tween.tween_property(interact_button, "modulate:a", 1.0, 0.3)

func _on_chat_box_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		# Hide the button with a fade-out effect
		var tween = create_tween()
		tween.tween_property(interact_button, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func(): interact_button.visible = false)
		
		if merchant_menu and merchant_menu.visible:
			merchant_menu.toggle_merchant()

func toggle_shop() -> void:
	if merchant_menu:
		merchant_menu.toggle_merchant()

func _exit_tree() -> void:
	# Clean up the merchant menu when the merchant is removed
	if merchant_menu:
		merchant_menu.queue_free()

# Make sure button stays above the merchant
func _process(_delta: float) -> void:
	if interact_button.visible:
		# Update button position to stay above merchant
		interact_button.position = Vector2(-50, -80)  # Keep button above merchant
