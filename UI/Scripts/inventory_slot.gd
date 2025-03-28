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
	use_button.text = "EAT"  # Only show EAT button, no more READ

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

	# Enhanced EAT button styling
	use_button.add_theme_font_size_override("font_size", 24)
	use_button.custom_minimum_size = Vector2(80, 40)
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.2, 0.6, 0.2, 0.9)
	normal_style.border_color = Color(0.3, 0.8, 0.3, 1.0)
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_right = 8
	normal_style.corner_radius_bottom_left = 8
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.3, 0.7, 0.3, 1.0)
	hover_style.border_color = Color(0.4, 1.0, 0.4, 1.0)
	hover_style.border_width_left = 3
	hover_style.border_width_top = 3
	hover_style.border_width_right = 3
	hover_style.border_width_bottom = 3
	hover_style.corner_radius_top_left = 8
	hover_style.corner_radius_top_right = 8
	hover_style.corner_radius_bottom_right = 8
	hover_style.corner_radius_bottom_left = 8
	
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.15, 0.45, 0.15, 1.0)
	pressed_style.border_color = Color(0.2, 0.6, 0.2, 1.0)
	pressed_style.border_width_left = 2
	pressed_style.border_width_top = 2
	pressed_style.border_width_right = 2
	pressed_style.border_width_bottom = 2
	pressed_style.corner_radius_top_left = 8
	pressed_style.corner_radius_top_right = 8
	pressed_style.corner_radius_bottom_right = 8
	pressed_style.corner_radius_bottom_left = 8
	
	use_button.add_theme_stylebox_override("normal", normal_style)
	use_button.add_theme_stylebox_override("hover", hover_style)
	use_button.add_theme_stylebox_override("pressed", pressed_style)
	
	use_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	use_button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	use_button.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.9, 1))

func set_item(data: Dictionary) -> void:
	if !is_instance_valid(self) or !is_inside_tree():
		return
		
	item_data = data
	
	if item_data.size() == 0:
		if is_instance_valid(texture_rect):
			texture_rect.texture = null
		return
	
	if is_instance_valid(texture_rect):
		texture_rect.texture = item_data.texture
	if is_instance_valid(external_quantity_label):
		external_quantity_label.text = "x%d" % item_data.get("quantity", 1)
	
	# Clear existing instances
	_clear_instances()
	
	# Set the item name
	if is_instance_valid(name_label):
		if data.has("name"):
			name_label.text = data.name
			name_label.show()
		else:
			name_label.text = data.id.capitalize().replace("_", " ")
			name_label.show()
	
	# Show external quantity label with correct quantity
	if is_instance_valid(external_quantity_label):
		external_quantity_label.show()
	
	# Handle different item types
	if item_data.get("type") == "lore":  # Check by type instead of ID
		# Wait a frame to ensure previous instance is fully cleaned up
		await get_tree().process_frame
		
		if !is_instance_valid(self) or !is_inside_tree():
			return
			
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
			if is_instance_valid(texture_rect):
				texture_rect.hide()
	elif item_data.id == "celestial_tear":
		# Wait a frame to ensure previous instance is fully cleaned up
		await get_tree().process_frame
		
		if !is_instance_valid(self) or !is_inside_tree():
			return
			
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
			if is_instance_valid(texture_rect):
				texture_rect.hide()
	else:
		# Default case for other items
		if is_instance_valid(texture_rect):
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
	if !is_instance_valid(self) or !is_inside_tree():
		return
		
	var details_panel = get_node_or_null("../../ItemDetails")
	if not details_panel or !is_instance_valid(details_panel):
		return
		
	var detail_slot = details_panel.get_node_or_null("DetailSlot")
	var item_name = details_panel.get_node_or_null("ItemName")
	var item_description = details_panel.get_node_or_null("ItemDescription")
	
	if not detail_slot or not item_name or not item_description or !is_instance_valid(detail_slot) or !is_instance_valid(item_name) or !is_instance_valid(item_description):
		return
	
	# Clear any existing instances in the detail slot
	for child in detail_slot.get_children():
		if is_instance_valid(child):
			child.queue_free()
	
	# Handle items based on type instead of ID
	if item_data.get("type") == "lore":
		if is_instance_valid(item_name):
			item_name.text = item_data.get("name", "Ancient Fragment")
		# Always show description
		if is_instance_valid(item_description):
			item_description.text = item_data.get("description", "A Piece Of Knowledge From The Old Era. Sells For A Really High Price")
			item_description.add_theme_font_size_override("font_size", 24)
		
		# Create a larger instance of the lore fragment
		if is_instance_valid(detail_slot):
			var large_lore = LORE_FRAGMENT_SCENE.instantiate()
			detail_slot.add_child(large_lore)
			if large_lore is Node2D:
				large_lore.scale = Vector2(5.5, 5.5)
				if large_lore.has_node("Sprite2D"):
					var sprite = large_lore.get_node("Sprite2D")
					sprite.centered = true
					large_lore.position = Vector2(
						detail_slot.size.x / 2,
						(detail_slot.size.y / 2) + 30
					)
	elif item_data.id == "celestial_tear":
		if is_instance_valid(item_name):
			item_name.text = "Celestial Tear"
		if is_instance_valid(item_description):
			item_description.text = "A crystallized tear from the heavens. Restores full health and stamina when consumed."
			item_description.add_theme_font_size_override("font_size", 24)
		
		if is_instance_valid(detail_slot):
			var large_tear = CELESTIAL_TEAR_SCENE.instantiate()
			detail_slot.add_child(large_tear)
			if large_tear is Node2D:
				large_tear.scale = Vector2(8.0, 8.0)
				large_tear.position = detail_slot.size / 2

func _on_mouse_entered() -> void:
	if !is_instance_valid(self) or !is_inside_tree():
		return
		
	if item_data.size() > 0:
		_update_item_details()
		is_hovering = true
		
		if item_data.get("use_function"):
			# Only show EAT button for non-lore items
			if item_data.get("type") != "lore":
				use_button.text = "EAT"
				use_button.show()
				hide_timer.stop()

func _on_mouse_exited() -> void:
	if !is_instance_valid(self) or !is_inside_tree():
		return
		
	is_hovering = false
	if is_instance_valid(hide_timer) and hide_timer.is_inside_tree():
		hide_timer.start()

func _on_hide_timer_timeout() -> void:
	if !is_instance_valid(self) or !is_inside_tree():
		return
		
	if not is_hovering and is_instance_valid(use_button):
		use_button.hide()

func _on_use_button_pressed() -> void:
	if !is_instance_valid(self) or !is_inside_tree():
		return
		
	if item_data.has("id"):  # Check if we have valid item data
		# Emit the signal through SignalBus first
		SignalBus.item_used.emit(item_data)
		
		if item_data.get("type") == "lore":  # Check if it's a lore item
			if not item_data.get("has_been_read", false):
				# Mark as read and update the item data
				item_data["has_been_read"] = true
				item_data["unread"] = false  # Mark as no longer unread for sales
				# Update the display
				_update_item_details()
				# Update in inventory system
				if has_node("/root/Inventory"):
					var inventory = get_node("/root/Inventory")
					inventory.update_item(item_data.id, item_data)
				# Hide the READ button permanently for this lore item
				if is_instance_valid(use_button):
					use_button.hide()
		else:
			# For non-lore items, use them normally
			Inventory.use_item(item_data.id)
			clear_slot()
			if is_instance_valid(use_button):
				use_button.hide()

func clear_slot() -> void:
	if !is_instance_valid(self) or !is_inside_tree():
		return
		
	# Clear item data and read state
	item_data = {}
	is_empty = true
	has_been_read = false
	
	# Clear instances
	_clear_instances()
	
	# Reset texture
	if is_instance_valid(texture_rect):
		texture_rect.texture = null
		texture_rect.hide()
		texture_rect.scale = Vector2.ONE
		texture_rect.custom_minimum_size = Vector2(80, 80)  # Keep consistent size
	
	# Hide labels
	if is_instance_valid(name_label):
		name_label.hide()
		name_label.text = ""
	if is_instance_valid(external_quantity_label):
		external_quantity_label.hide()
		external_quantity_label.text = "x1"
	
	# Hide use button
	if is_instance_valid(use_button):
		use_button.hide()

# Add cleanup on exit
func _exit_tree() -> void:
	_clear_instances()
	
	# Clean up timer if it exists
	if is_instance_valid(hide_timer):
		hide_timer.queue_free()
