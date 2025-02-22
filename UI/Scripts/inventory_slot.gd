extends Panel

@onready var texture_rect = $TextureRect
@onready var name_label = $NameLabel
@onready var use_button = $UseButton
@onready var hide_timer = Timer.new()
@onready var item_container = $ItemContainer
@onready var external_quantity_label = $ExternalQuantityLabel

const BUTTON_VISIBLE_TIME = 1.5  # Time in seconds to keep button visible
const CELESTIAL_TEAR_SCENE = preload("res://Objects/Scenes/Collectibles/CelestialTear/celestial_tear.tscn")
const LORE_FRAGMENT_SCENE = preload("res://Objects/Scenes/Collectibles/LoreFragment/lore_fragment.tscn")

var item_data: Dictionary = {}
var is_hovering: bool = false
var tear_instance = null
var lore_instance = null
var is_empty: bool = true
var has_been_read: bool = false  # Track if lore has been read

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
	
	# Set up texture rect properties
	texture_rect.custom_minimum_size = Vector2(80, 80)  # Adjusted size
	texture_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	texture_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER

func set_item(data: Dictionary) -> void:
	print("Setting item with data: ", data)  # Debug print
	item_data = data
	is_empty = false
	has_been_read = data.get("has_been_read", false)  # Get read state from item data
	
	# Clear existing instances
	_clear_instances()
	
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
	
	# Handle different item types
	match data.id:  # Match by ID instead of type
		"celestial_tear":
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
		"LORE_001":  # Match lore by ID
			print("Creating lore fragment instance")  # Debug print
			# Wait a frame to ensure previous instance is fully cleaned up
			await get_tree().process_frame
			lore_instance = LORE_FRAGMENT_SCENE.instantiate()
			
			# Make sure the item_container still exists before adding
			if is_instance_valid(item_container) and item_container.is_inside_tree():
				item_container.add_child(lore_instance)
				
				# Adjust the size and position of the lore instance
				if lore_instance is Node2D:
					lore_instance.scale = Vector2(2.5, 2.5)  # Increased scale for better visibility
					# Center in the slot
					var slot_size = size
					lore_instance.position = slot_size / 2
				
				# Hide the default texture
				texture_rect.hide()
		_:
			# Default case for other items
			texture_rect.texture = data.texture
			texture_rect.show()
			texture_rect.material = null  # Clear any existing shader
			texture_rect.scale = Vector2.ONE
			texture_rect.custom_minimum_size = Vector2(80, 80)
			texture_rect.pivot_offset = texture_rect.size / 2

func _clear_instances() -> void:
	# Clear existing tear instance if any
	if is_instance_valid(tear_instance):
		if tear_instance.is_inside_tree():
			item_container.remove_child(tear_instance)
		tear_instance.queue_free()
		tear_instance = null
	
	# Clear existing lore instance if any
	if is_instance_valid(lore_instance):
		if lore_instance.is_inside_tree():
			item_container.remove_child(lore_instance)
		lore_instance.queue_free()
		lore_instance = null

func _update_item_details() -> void:
	var details_panel = get_node_or_null("../../ItemDetails")
	if not details_panel:
		return
		
	var detail_slot = details_panel.get_node_or_null("DetailSlot")
	var item_name = details_panel.get_node_or_null("ItemName")
	var item_description = details_panel.get_node_or_null("ItemDescription")
	
	if not detail_slot or not item_name or not item_description:
		return
	
	# Clear any existing instances in the detail slot
	for child in detail_slot.get_children():
		child.queue_free()
	
	match item_data.id:  # Match by ID instead of type
		"celestial_tear":
			item_name.text = "Celestial Tear"
			item_description.text = "A crystallized tear from the heavens. Restores full health and stamina when consumed."
			item_description.add_theme_font_size_override("font_size", 24)  # Reset font size
			
			# Create a larger instance of the tear
			var large_tear = CELESTIAL_TEAR_SCENE.instantiate()
			detail_slot.add_child(large_tear)
			if large_tear is Node2D:
				large_tear.scale = Vector2(8.0, 8.0)
				large_tear.position = detail_slot.size / 2
				
		"LORE_001":  # Match lore by ID
			item_name.text = "Lore Fragment"
			if has_been_read:
				item_description.text = "Potatoes are Great, But Potatoes are great"
				item_description.add_theme_font_size_override("font_size", 24)
			else:
				item_description.text = "....."
				item_description.add_theme_font_size_override("font_size", 48)
			
			# Create a larger instance of the lore fragment
			var large_lore = LORE_FRAGMENT_SCENE.instantiate()
			detail_slot.add_child(large_lore)
			if large_lore is Node2D:
				# Make it bigger
				large_lore.scale = Vector2(5.5, 5.5)  # Increased from 4.5 to 5.5
				
				# Ensure proper centering with specific Y offset
				if large_lore.has_node("Sprite2D"):
					var sprite = large_lore.get_node("Sprite2D")
					sprite.centered = true
					# Position relative to detail slot center with +50 Y offset
					large_lore.position = Vector2(
						detail_slot.size.x / 2,  # Exact horizontal center
						(detail_slot.size.y / 2) + 30  # Center with +50 offset
					)

func _on_mouse_entered() -> void:
	is_hovering = true
	print("Mouse entered, item_data: ", item_data)  # Debug print
	
	# Update item details
	_update_item_details()
	
	if item_data.get("use_function"):
		# Only show READ button if lore is unread
		if item_data.id == "LORE_001":
			if not has_been_read:
				use_button.text = "READ"
				use_button.show()
		else:
			use_button.text = "EAT"
			use_button.show()
		
		# Position the button to the right of the slot
		use_button.position = Vector2(
			size.x + 10,  # 10 pixels gap from the slot
			(size.y - use_button.size.y) / 2  # Vertically centered
		)
		
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
		# Emit the signal through SignalBus first
		SignalBus.item_used.emit(item_data)
		
		if item_data.id == "LORE_001":  # Check lore by ID
			if not has_been_read:
				# Mark as read and update the item data
				has_been_read = true
				item_data["has_been_read"] = true
				item_data["unread"] = false  # Mark as no longer unread for sales
				# Update the display
				_update_item_details()
				# Update in inventory system
				if has_node("/root/Inventory"):
					var inventory = get_node("/root/Inventory")
					inventory.update_item(item_data.id, item_data)
		
		# Use the item through the Inventory singleton
		Inventory.use_item(item_data.id)
		
		# For non-lore items, clear the slot after use
		if item_data.id != "LORE_001":  # Check by ID
			clear_slot()
		
		# Hide the use button
		use_button.hide()

func clear_slot() -> void:
	# Clear item data and read state
	item_data = {}
	is_empty = true
	has_been_read = false
	
	# Clear instances
	_clear_instances()
	
	# Reset texture
	texture_rect.texture = null
	texture_rect.hide()
	texture_rect.scale = Vector2.ONE
	texture_rect.custom_minimum_size = Vector2(80, 80)  # Keep consistent size
	
	# Hide labels
	name_label.hide()
	name_label.text = ""
	external_quantity_label.hide()
	external_quantity_label.text = "x1"
	
	# Hide use button
	use_button.hide()

# Add cleanup on exit
func _exit_tree() -> void:
	_clear_instances()
	
	# Clean up timer if it exists
	if is_instance_valid(hide_timer):
		hide_timer.queue_free()
