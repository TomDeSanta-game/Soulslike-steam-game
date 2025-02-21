extends Panel

@onready var texture_rect = $TextureRect
@onready var name_label = $NameLabel
@onready var use_button = $UseButton
@onready var hide_timer = Timer.new()
@onready var item_container = $ItemContainer
@onready var external_quantity_label = $ExternalQuantityLabel

const BUTTON_VISIBLE_TIME = 1.5  # Time in seconds to keep button visible
const CELESTIAL_TEAR_SCENE = preload("res://Objects/Scenes/Collectibles/CelestialTear/celestial_tear.tscn")

var item_data: Dictionary = {}
var is_hovering: bool = false
var tear_instance = null
var is_empty: bool = true

func _ready() -> void:
	# Hide use button initially
	use_button.hide()
	use_button.text = "READ"  # Change to READ for lore items

	# Setup timer
	hide_timer.one_shot = true
	hide_timer.wait_time = BUTTON_VISIBLE_TIME
	hide_timer.timeout.connect(_on_hide_timer_timeout)
	add_child(hide_timer)
	hide_timer.process_mode = Node.PROCESS_MODE_PAUSABLE

	# Connect signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	use_button.pressed.connect(_on_use_button_pressed)

	# Initialize external quantity label
	external_quantity_label.text = "x1"

func set_item(data: Dictionary) -> void:
	print("Setting item with data: ", data)  # Debug print
	item_data = data
	is_empty = false
	
	# Clear existing tear instance if any
	if is_instance_valid(tear_instance):
		# Make sure to remove from tree before freeing
		if tear_instance.is_inside_tree():
			item_container.remove_child(tear_instance)
		tear_instance.queue_free()
		tear_instance = null
	
	# Set the item name
	if data.has("name"):
		name_label.text = data.name
		name_label.show()
	else:
		name_label.text = data.id.capitalize().replace("_", " ")
		name_label.show()
	
	# Show external quantity label with correct quantity
	external_quantity_label.show()
	external_quantity_label.text = "x%d" % data.get("quantity", 1)
	
	# If this is a celestial tear, instantiate the scene
	if data.id == "celestial_tear":
		print("Creating celestial tear instance")  # Debug print
		# Wait a frame to ensure previous instance is fully cleaned up
		await get_tree().process_frame
		tear_instance = CELESTIAL_TEAR_SCENE.instantiate()
		
		# Make sure the item_container still exists before adding
		if is_instance_valid(item_container) and item_container.is_inside_tree():
			item_container.add_child(tear_instance)
			
			# Adjust the size and position of the tear instance
			if tear_instance is Node2D:
				tear_instance.scale = Vector2(4.0, 4.0)  # Larger scale for better visibility
				# Center the tear in the slot by using the slot's size
				var slot_size = size
				tear_instance.position = slot_size / 2
			
			# Hide the default texture
			texture_rect.hide()
	else:
		texture_rect.texture = data.texture
		texture_rect.show()
		
		# Apply custom inventory scale if provided
		if data.has("inventory_scale"):
			texture_rect.scale = data.inventory_scale
		else:
			texture_rect.scale = Vector2.ONE
			
		# Center the texture in the slot
		texture_rect.pivot_offset = texture_rect.size / 2
		texture_rect.position = size / 2

func _on_mouse_entered() -> void:
	is_hovering = true
	print("Mouse entered, item_data: ", item_data)  # Debug print
	if item_data.get("use_function"):
		use_button.text = "READ" if item_data.get("type") == "lore" else "EAT"
		use_button.show()
		hide_timer.stop()

func _on_mouse_exited() -> void:
	is_hovering = false
	if is_instance_valid(hide_timer) and hide_timer.is_inside_tree():
		hide_timer.start()

func _on_hide_timer_timeout() -> void:
	if not is_hovering:
		use_button.hide()

func _on_use_button_pressed() -> void:
	if item_data.has("id"):  # Check if we have valid item data
		# Emit the signal through SignalBus
		SignalBus.item_used.emit(item_data)
		
		# Use the item through the Inventory singleton
		Inventory.use_item(item_data.id)
		
		# Hide the use button
		use_button.hide()
		
		# Clear the slot if item was used
		clear_slot()

func clear_slot() -> void:
	# Clear item data
	item_data = {}
	is_empty = true
	
	# Clear existing tear instance if any
	if is_instance_valid(tear_instance):
		# Make sure to remove from tree before freeing
		if tear_instance.is_inside_tree():
			item_container.remove_child(tear_instance)
		tear_instance.queue_free()
		tear_instance = null
	
	# Reset texture
	texture_rect.texture = null
	texture_rect.hide()
	texture_rect.scale = Vector2.ONE
	
	# Hide labels
	name_label.hide()
	name_label.text = ""
	external_quantity_label.hide()
	external_quantity_label.text = "x1"
	
	# Hide use button
	use_button.hide()

# Add cleanup on exit
func _exit_tree() -> void:
	# Ensure tear instance is properly cleaned up
	if is_instance_valid(tear_instance):
		if tear_instance.is_inside_tree():
			item_container.remove_child(tear_instance)
		tear_instance.queue_free()
		tear_instance = null
	
	# Clean up timer if it exists
	if is_instance_valid(hide_timer):
		hide_timer.queue_free()
