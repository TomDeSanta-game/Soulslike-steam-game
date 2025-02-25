class_name MerchantMenu
extends Control

const CELESTIAL_TEAR_SCENE = preload(
	"res://Objects/Scenes/Collectibles/CelestialTear/celestial_tear.tscn"
)
const LORE_FRAGMENT_SCENE = preload(
	"res://Objects/Scenes/Collectibles/LoreFragment/lore_fragment.tscn"
)

@onready var merchant_grid: GridContainer = $Panel/MerchantInventory/ItemGrid
@onready var player_grid: GridContainer = $Panel/PlayerInventory/ItemGrid
@onready var item_slot_scene: PackedScene = preload("res://UI/Scenes/inventory_slot.tscn")
@onready var item_sprite: TextureRect = $Panel/ItemDetails/ItemSprite
@onready var item_name_label: Label = $Panel/ItemDetails/InfoPanel/ItemName
@onready var item_description_label: Label = $Panel/ItemDetails/InfoPanel/ItemDescription
@onready var price_label: Label = $Panel/ItemDetails/InfoPanel/Price
@onready var buy_button: Button = $Panel/ItemDetails/InfoPanel/BuyButton
@onready var sell_button: Button = $Panel/ItemDetails/InfoPanel/SellButton
@onready var close_button: Button = $Panel/CloseButton
@onready var title_label: Label = $Panel/Title
@onready var insufficient_souls_label: Label = $Panel/ItemDetails/InfoPanel/InsufficientSouls

var selected_item: Dictionary = {}
var merchant_inventory: Dictionary = {}
var selected_from_merchant: bool = false
var sprite_animation_player: AnimationPlayer

# Style configurations
const BUTTON_STYLES = {
	"normal":
	{
		"bg_color": Color(0.2, 0.2, 0.2, 0.8),
		"border_color": Color(0.4, 0.4, 0.4, 1.0),
		"border_width": 2,
		"corner_radius": 8
	},
	"highlighted":
	{
		"bg_color": Color(0.3, 0.7, 0.3, 1.0),
		"border_color": Color(0.4, 1.0, 0.4, 1.0),
		"border_width": 3,
		"corner_radius": 8
	},
	"disabled":
	{
		"bg_color": Color(0.5, 0.1, 0.1, 0.8),
		"border_color": Color(0.8, 0.2, 0.2, 1.0),
		"border_width": 2,
		"corner_radius": 8
	}
}


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Setup close button
	if !close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)

	close_button.mouse_filter = Control.MOUSE_FILTER_STOP
	close_button.focus_mode = Control.FOCUS_ALL
	close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_button.custom_minimum_size = Vector2(100, 60)
	close_button.add_theme_font_size_override("font_size", 36)
	close_button.flat = false
	close_button.z_index = 1

	# Ensure parent panels allow input to pass through to children
	$Panel.mouse_filter = Control.MOUSE_FILTER_PASS
	$Panel/ItemDetails.mouse_filter = Control.MOUSE_FILTER_PASS
	$Panel/ItemDetails/InfoPanel.mouse_filter = Control.MOUSE_FILTER_PASS

	# Setup insufficient souls label
	insufficient_souls_label.visible = false
	insufficient_souls_label.modulate = Color(1, 0, 0, 1)
	insufficient_souls_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	insufficient_souls_label.z_index = 100

	# Move label to Panel root
	var info_panel = insufficient_souls_label.get_parent()
	if info_panel:
		info_panel.remove_child(insufficient_souls_label)
		$Panel.add_child(insufficient_souls_label)

		# Set up anchors properly
		insufficient_souls_label.anchor_left = 0.5
		insufficient_souls_label.anchor_right = 0.5
		insufficient_souls_label.anchor_top = 0.5
		insufficient_souls_label.anchor_bottom = 0.5

		# Use set_deferred for size and position
		insufficient_souls_label.set_deferred("custom_minimum_size", Vector2(200, 50))
		insufficient_souls_label.set_deferred(
			"position", Vector2($Panel.size.x / 2 - 100, $Panel.size.y / 2 - 25)
		)

		# Set grow directions
		insufficient_souls_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
		insufficient_souls_label.grow_vertical = Control.GROW_DIRECTION_BOTH

	# Ensure buy button is properly set up first
	buy_button.mouse_filter = Control.MOUSE_FILTER_STOP
	buy_button.focus_mode = Control.FOCUS_ALL
	buy_button.visible = true
	buy_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	buy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	buy_button.custom_minimum_size = Vector2(200, 60)  # Increased size
	buy_button.add_theme_font_size_override("font_size", 24)  # Larger font
	buy_button.flat = false
	buy_button.z_index = 1

	# Connect button signals
	if !buy_button.gui_input.is_connected(_on_buy_button_gui_input):
		buy_button.gui_input.connect(_on_buy_button_gui_input)
	if !buy_button.button_down.is_connected(_on_buy_button_click):
		buy_button.button_down.connect(_on_buy_button_click)

	# Set up sell button similarly
	sell_button.mouse_filter = Control.MOUSE_FILTER_STOP
	sell_button.focus_mode = Control.FOCUS_ALL
	sell_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	sell_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sell_button.custom_minimum_size = Vector2(200, 60)  # Increased size
	sell_button.add_theme_font_size_override("font_size", 24)  # Larger font
	sell_button.flat = false
	sell_button.z_index = 1

	# Connect other signals
	if !sell_button.pressed.is_connected(_on_sell_pressed):
		sell_button.pressed.connect(_on_sell_pressed)
	if !Inventory.inventory_updated.is_connected(_on_inventory_updated):
		Inventory.inventory_updated.connect(_on_inventory_updated)
	if !SignalBus.trade_completed.is_connected(_on_trade_completed):
		SignalBus.trade_completed.connect(_on_trade_completed)

	# Setup button styles
	_setup_button_styles()


func _cleanup_signals() -> void:
	if buy_button.pressed.is_connected(_on_buy_pressed):
		buy_button.pressed.disconnect(_on_buy_pressed)
	if buy_button.gui_input.is_connected(_on_buy_button_gui_input):
		buy_button.gui_input.disconnect(_on_buy_button_gui_input)
	if buy_button.button_down.is_connected(_on_buy_button_click):
		buy_button.button_down.disconnect(_on_buy_button_click)
	if sell_button.pressed.is_connected(_on_sell_pressed):
		sell_button.pressed.disconnect(_on_sell_pressed)
	if close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.disconnect(_on_close_pressed)
	if Inventory.inventory_updated.is_connected(_on_inventory_updated):
		Inventory.inventory_updated.disconnect(_on_inventory_updated)
	if SignalBus.trade_completed.is_connected(_on_trade_completed):
		SignalBus.trade_completed.disconnect(_on_trade_completed)


func _setup_button_styles() -> void:
	for button in [buy_button, sell_button]:
		var normal_style = StyleBoxFlat.new()
		var hover_style = StyleBoxFlat.new()
		var disabled_style = StyleBoxFlat.new()

		# Normal style
		normal_style.bg_color = BUTTON_STYLES.normal.bg_color
		normal_style.border_color = BUTTON_STYLES.normal.border_color
		normal_style.border_width_left = BUTTON_STYLES.normal.border_width
		normal_style.border_width_right = BUTTON_STYLES.normal.border_width
		normal_style.border_width_top = BUTTON_STYLES.normal.border_width
		normal_style.border_width_bottom = BUTTON_STYLES.normal.border_width
		normal_style.corner_radius_top_left = BUTTON_STYLES.normal.corner_radius
		normal_style.corner_radius_top_right = BUTTON_STYLES.normal.corner_radius
		normal_style.corner_radius_bottom_left = BUTTON_STYLES.normal.corner_radius
		normal_style.corner_radius_bottom_right = BUTTON_STYLES.normal.corner_radius

		# Hover style
		hover_style.bg_color = BUTTON_STYLES.highlighted.bg_color
		hover_style.border_color = BUTTON_STYLES.highlighted.border_color
		hover_style.border_width_left = BUTTON_STYLES.highlighted.border_width
		hover_style.border_width_right = BUTTON_STYLES.highlighted.border_width
		hover_style.border_width_top = BUTTON_STYLES.highlighted.border_width
		hover_style.border_width_bottom = BUTTON_STYLES.highlighted.border_width
		hover_style.corner_radius_top_left = BUTTON_STYLES.highlighted.corner_radius
		hover_style.corner_radius_top_right = BUTTON_STYLES.highlighted.corner_radius
		hover_style.corner_radius_bottom_left = BUTTON_STYLES.highlighted.corner_radius
		hover_style.corner_radius_bottom_right = BUTTON_STYLES.highlighted.corner_radius

		# Disabled style
		disabled_style.bg_color = BUTTON_STYLES.disabled.bg_color
		disabled_style.border_color = BUTTON_STYLES.disabled.border_color
		disabled_style.border_width_left = BUTTON_STYLES.disabled.border_width
		disabled_style.border_width_right = BUTTON_STYLES.disabled.border_width
		disabled_style.border_width_top = BUTTON_STYLES.disabled.border_width
		disabled_style.border_width_bottom = BUTTON_STYLES.disabled.border_width
		disabled_style.corner_radius_top_left = BUTTON_STYLES.disabled.corner_radius
		disabled_style.corner_radius_top_right = BUTTON_STYLES.disabled.corner_radius
		disabled_style.corner_radius_bottom_left = BUTTON_STYLES.disabled.corner_radius
		disabled_style.corner_radius_bottom_right = BUTTON_STYLES.disabled.corner_radius

		button.add_theme_stylebox_override("normal", normal_style)
		button.add_theme_stylebox_override("hover", hover_style)
		button.add_theme_stylebox_override("disabled", disabled_style)

		# Set button text color
		button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
		button.add_theme_color_override("font_disabled_color", Color(0.7, 0.7, 0.7, 1))


func _on_buy_button_click() -> void:
	if !buy_button.disabled:
		_on_buy_pressed()


func _on_buy_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if buy_button.disabled:
				_show_insufficient_souls_feedback()
			else:
				_on_buy_pressed()  # Only call buy pressed if button isn't disabled
				get_viewport().set_input_as_handled()  # Mark input as handled


func _setup_item_sprite(item_data: Dictionary) -> void:
	if !is_instance_valid(item_sprite):
		return

	# Clear any existing children first
	for child in item_sprite.get_children():
		if is_instance_valid(child):
			child.queue_free()

	# Reset sprite properties
	item_sprite.texture = null
	item_sprite.material = null
	item_sprite.modulate = Color.WHITE

	# Handle different item types
	if item_data.get("type") == "lore":
		var lore_instance = LORE_FRAGMENT_SCENE.instantiate()
		item_sprite.add_child(lore_instance)
		if lore_instance is Node2D:
			lore_instance.scale = Vector2(5.5, 5.5)
			var center_pos = item_sprite.size / 2
			lore_instance.position = Vector2(center_pos.x, center_pos.y + 25)

			# The lore fragment scene already has an AnimationPlayer with "idle" animation
			# that moves it up and down, so we don't need to add any animation

			# Add shader if item has one
			if item_data.has("shader"):
				var shader_material = ShaderMaterial.new()
				shader_material.shader = item_data.shader
				lore_instance.material = shader_material

				# Update shader time
				var timer = Timer.new()
				lore_instance.add_child(timer)
				timer.wait_time = 0.016
				timer.timeout.connect(
					func():
						shader_material.set_shader_parameter(
							"time_elapsed", Time.get_ticks_msec() / 1000.0
						)
				)
				timer.start()

	elif item_data.get("id", "") == "celestial_tear":
		var tear_instance = CELESTIAL_TEAR_SCENE.instantiate()
		item_sprite.add_child(tear_instance)
		if tear_instance is Node2D:
			tear_instance.scale = Vector2(8.0, 8.0)
			tear_instance.position = item_sprite.size / 2

			# The celestial tear scene already has an AnimationPlayer with "ANIMATION" animation
			# that scales it up and down, so we don't need to add any animation

			# Add shader if item has one
			if item_data.has("shader"):
				var shader_material = ShaderMaterial.new()
				shader_material.shader = item_data.shader
				tear_instance.material = shader_material

				# Update shader time
				var timer = Timer.new()
				tear_instance.add_child(timer)
				timer.wait_time = 0.016
				timer.timeout.connect(
					func():
						shader_material.set_shader_parameter(
							"time_elapsed", Time.get_ticks_msec() / 1000.0
						)
				)
				timer.start()

	elif item_data.has("frames"):
		var sprite = AnimatedSprite2D.new()
		sprite.sprite_frames = item_data.frames
		sprite.centered = true
		sprite.play("default")
		item_sprite.add_child(sprite)

		sprite.position = item_sprite.size / 2
		sprite.scale = Vector2(3, 3)
		sprite.show()
		sprite.playing = true

		# Add shader if item has one
		if item_data.has("shader"):
			var shader_material = ShaderMaterial.new()
			shader_material.shader = item_data.shader
			sprite.material = shader_material

			# Update shader time
			var timer = Timer.new()
			sprite.add_child(timer)
			timer.wait_time = 0.016
			timer.timeout.connect(
				func():
					shader_material.set_shader_parameter(
						"time_elapsed", Time.get_ticks_msec() / 1000.0
					)
			)
			timer.start()

	elif item_data.has("texture"):
		item_sprite.texture = item_data.texture

		# Add shader if item has one
		if item_data.has("shader"):
			var shader_material = ShaderMaterial.new()
			shader_material.shader = item_data.shader
			item_sprite.material = shader_material

			# Update shader time
			var timer = Timer.new()
			item_sprite.add_child(timer)
			timer.wait_time = 0.016
			timer.timeout.connect(
				func():
					shader_material.set_shader_parameter(
						"time_elapsed", Time.get_ticks_msec() / 1000.0
					)
			)
			timer.start()


func _update_button_state(button: Button, _visible: bool, disabled: bool, text: String = "") -> void:
	if !is_instance_valid(button):
		return

	button.visible = _visible
	button.disabled = disabled
	if text:
		button.text = text

	# Show/hide insufficient souls label
	if is_instance_valid(insufficient_souls_label):
		insufficient_souls_label.visible = disabled and visible and selected_from_merchant


func _on_buy_pressed() -> void:
	if selected_item.is_empty() or !selected_from_merchant:
		return

	var item_id = selected_item.get("id", "")
	if item_id == "":
		return

	var price: int = selected_item.get("price", 0)

	if SoulsSystem.get_souls() >= price:
		var quantity = merchant_inventory.get(item_id, {}).get("quantity", 0)
		if quantity > 0:
			# Try to spend souls
			if SoulsSystem.spend_souls(price):
				# Add item to player inventory
				Inventory.add_item(item_id, selected_item)
				# Update merchant inventory
				merchant_inventory[item_id].quantity -= 1
				if merchant_inventory[item_id].quantity <= 0:
					merchant_inventory.erase(item_id)
				# Update display
				_update_display()
				# Play purchase sound
				SoundManager.play_sound(Sound.collect, "SFX")
				# Show success feedback
				_show_purchase_feedback()
			else:
				_show_insufficient_souls_feedback()
	else:
		_show_insufficient_souls_feedback()


func _show_purchase_feedback() -> void:
	if !is_instance_valid(item_sprite):
		return

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_OUT)

	# Scale up and back
	tween.tween_property(item_sprite, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(item_sprite, "scale", Vector2(1.0, 1.0), 0.1)

	# Flash effect
	tween.parallel().tween_property(item_sprite, "modulate", Color(2, 2, 2, 1), 0.1)
	tween.parallel().tween_property(item_sprite, "modulate", Color(1, 1, 1, 1), 0.1)


func _show_insufficient_souls_feedback() -> void:
	if !is_instance_valid(insufficient_souls_label):
		return

	# Reset and show label at top position
	insufficient_souls_label.show()
	insufficient_souls_label.text = "NOT ENOUGH SOULS!"
	insufficient_souls_label.modulate = Color(0.6, 0, 0, 1)  # Darker, more soulslike red

	# Position at top center of panel
	var start_y = $Panel.size.y * 0.2  # Start at 20% from the top
	var end_y = $Panel.size.y + 100    # Move completely off screen
	insufficient_souls_label.position = Vector2(
		$Panel.size.x / 2 - insufficient_souls_label.size.x / 2,
		start_y
	)

	# Create tween sequence
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	
	# Stay still for exactly 1.0 seconds
	tween.tween_interval(1.0)
	
	# Then instantly move down (0.1 seconds for very fast movement)
	tween.tween_property(insufficient_souls_label, "position:y", end_y, 0.1)
	
	# Reset after animation
	tween.tween_callback(func():
		# Reset position and hide for next time
		insufficient_souls_label.hide()
		insufficient_souls_label.position = Vector2(
			$Panel.size.x / 2 - insufficient_souls_label.size.x / 2,
			start_y
		)
	)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or event.is_action_pressed("BACK"):
		_on_close_pressed()


func set_merchant_name(merchant_name: String) -> void:
	title_label.text = merchant_name


func set_merchant_inventory(inventory: Dictionary) -> void:
	merchant_inventory = inventory
	if visible:
		_update_display()


func toggle_merchant() -> void:
	if !is_instance_valid(self) or !is_inside_tree():
		return

	if visible:
		_on_close_pressed()
	else:
		if InventoryStateManager.open_inventory("merchant"):
			visible = true
			if is_inside_tree() and get_tree():
				get_tree().paused = true

			# Ensure signals are connected
			if !close_button.pressed.is_connected(_on_close_pressed):
				close_button.pressed.connect(_on_close_pressed)
			if !buy_button.pressed.is_connected(_on_buy_pressed):
				buy_button.pressed.connect(_on_buy_pressed)

			_update_display()


func _on_close_pressed() -> void:
	if !is_instance_valid(self) or !is_inside_tree():
		return

	visible = false
	if is_inside_tree() and get_tree():  # Check if we have access to the tree
		get_tree().paused = false
	InventoryStateManager.close_inventory("merchant")
	_clear_item_details()

	# Play UI sound
	# SoundManager.play_sound(Sound.menu_back, "UI")


func _update_display() -> void:
	_update_merchant_grid()
	_update_player_grid()
	_clear_item_details()


func _disable_slot_actions(slot: Node) -> void:
	if slot.has_method("disable_hover_text"):
		slot.disable_hover_text()
	if slot.has_method("disable_action_buttons"):
		slot.disable_action_buttons()
	if slot.has_method("set_action_buttons_visible"):
		slot.set_action_buttons_visible(false)
	if slot.has_method("hide_action_buttons"):
		slot.hide_action_buttons()
	# Force hide any buttons that might be children of the slot
	for child in slot.get_children():
		if child is Button:
			child.visible = false
			child.disabled = true
		# Also check for action buttons in container nodes
		if child is Container:
			for subchild in child.get_children():
				if subchild is Button:
					subchild.visible = false
					subchild.disabled = true


func _setup_merchant_slot(slot: Node, item_data: Dictionary) -> Button:
	# Basic setup
	slot.set_item(item_data)

	# Disconnect any existing connections
	var existing_buttons = slot.get_children().filter(func(child): return child is Button)
	for button in existing_buttons:
		if button.pressed.is_connected(_on_merchant_item_selected.bind(item_data)):
			button.pressed.disconnect(_on_merchant_item_selected.bind(item_data))
		if button.pressed.is_connected(_on_player_item_selected.bind(item_data)):
			button.pressed.disconnect(_on_player_item_selected.bind(item_data))
		button.queue_free()

	# Create a simple click area
	var click_button = Button.new()
	click_button.flat = true
	click_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	click_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	click_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# Make the button transparent and expand to fill the slot
	click_button.modulate.a = 0.0
	click_button.custom_minimum_size = slot.size
	click_button.anchor_right = 1.0
	click_button.anchor_bottom = 1.0
	click_button.focus_mode = Control.FOCUS_NONE

	slot.add_child(click_button)

	# Connect the pressed signal
	if selected_from_merchant:
		click_button.pressed.connect(_on_merchant_item_selected.bind(item_data))
	else:
		click_button.pressed.connect(_on_player_item_selected.bind(item_data))

	return click_button


func _update_merchant_grid() -> void:
	if !is_instance_valid(merchant_grid):
		return

	for child in merchant_grid.get_children():
		if is_instance_valid(child):
			child.queue_free()

	for item_id in merchant_inventory:
		var item_data: Dictionary = merchant_inventory[item_id]
		var slot: Node = item_slot_scene.instantiate()
		merchant_grid.add_child(slot)
		selected_from_merchant = true
		var click_button = _setup_merchant_slot(slot, item_data)

		# Only connect if not already connected
		if !click_button.pressed.is_connected(_on_merchant_item_selected.bind(item_data)):
			click_button.pressed.connect(_on_merchant_item_selected.bind(item_data))


func _update_player_grid() -> void:
	if !is_instance_valid(player_grid):
		return

	for child in player_grid.get_children():
		if is_instance_valid(child):
			child.queue_free()

	for item_id in Inventory.get_items():
		var item_data: Dictionary = Inventory.get_items()[item_id]
		var slot: Node = item_slot_scene.instantiate()
		player_grid.add_child(slot)
		selected_from_merchant = false
		var click_button = _setup_merchant_slot(slot, item_data)

		# Only connect if not already connected
		if !click_button.pressed.is_connected(_on_player_item_selected.bind(item_data)):
			click_button.pressed.connect(_on_player_item_selected.bind(item_data))


func _on_merchant_item_selected(item_data: Dictionary) -> void:
	if !is_instance_valid(self) or !is_inside_tree():
		return

	selected_item = item_data
	selected_from_merchant = true
	_update_item_details()

	# Play selection sound
	SoundManager.play_sound(Sound.menu_select, "UI")


func _on_player_item_selected(item_data: Dictionary) -> void:
	if !is_instance_valid(self) or !is_inside_tree():
		return

	selected_item = item_data
	selected_from_merchant = false
	_update_item_details()

	# Play selection sound
	SoundManager.play_sound(Sound.menu_select, "UI")


func _update_item_details() -> void:
	if (
		!is_instance_valid(item_name_label)
		or !is_instance_valid(item_description_label)
		or !is_instance_valid(price_label)
	):
		return

	if selected_item.is_empty():
		_clear_item_details()
		return

	# Setup sprite and animations
	_setup_item_sprite(selected_item)

	# Update text
	if is_instance_valid(item_name_label):
		item_name_label.text = selected_item.get("name", "")
	if is_instance_valid(item_description_label):
		item_description_label.text = selected_item.get("description", "")

	if selected_from_merchant:
		var price = selected_item.get("price", 0)
		var can_afford = SoulsSystem.get_souls() >= price

		if is_instance_valid(price_label):
			price_label.text = "Buy for %s souls" % SoulsSystem.format_souls(price)

		# Ensure buy button is properly set up
		if is_instance_valid(buy_button):
			buy_button.show()
			buy_button.disabled = !can_afford
			buy_button.text = "BUY"
			buy_button.mouse_filter = Control.MOUSE_FILTER_STOP
			buy_button.focus_mode = Control.FOCUS_ALL
			buy_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			buy_button.flat = false
			buy_button.z_index = 1

			# Ensure button is visible and on top
			buy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			buy_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
			buy_button.custom_minimum_size = Vector2(200, 60)  # Increased size
			buy_button.add_theme_font_size_override("font_size", 24)  # Larger font

			# Reconnect signals if needed
			if !buy_button.pressed.is_connected(_on_buy_pressed):
				buy_button.pressed.connect(_on_buy_pressed)
			if !buy_button.button_down.is_connected(_on_buy_button_click):
				buy_button.button_down.connect(_on_buy_button_click)
			if !buy_button.gui_input.is_connected(_on_buy_button_gui_input):
				buy_button.gui_input.connect(_on_buy_button_gui_input)

		if is_instance_valid(sell_button):
			sell_button.hide()
	else:
		if is_instance_valid(buy_button):
			buy_button.hide()
		if is_instance_valid(sell_button):
			sell_button.show()
			sell_button.text = "SELL"
			sell_button.custom_minimum_size = Vector2(200, 60)  # Increased size
			sell_button.add_theme_font_size_override("font_size", 24)  # Larger font


func _clear_item_details() -> void:
	if (
		!is_instance_valid(item_sprite)
		or !is_instance_valid(item_name_label)
		or !is_instance_valid(item_description_label)
		or !is_instance_valid(price_label)
	):
		return

	# Clear sprite and any animations
	item_sprite.texture = null
	item_sprite.material = null
	for child in item_sprite.get_children():
		if is_instance_valid(child):
			child.queue_free()

	# Clear text
	if is_instance_valid(item_name_label):
		item_name_label.text = ""
	if is_instance_valid(item_description_label):
		item_description_label.text = ""
	if is_instance_valid(price_label):
		price_label.text = ""

	# Reset buttons
	if is_instance_valid(buy_button) and is_instance_valid(sell_button):
		buy_button.visible = false
		sell_button.visible = false
		selected_item = {}

	# Reset button styles
	_update_button_state(buy_button, false, false)
	_update_button_state(sell_button, false, false)

	# Hide insufficient souls label
	if is_instance_valid(insufficient_souls_label):
		insufficient_souls_label.visible = false


func _on_sell_pressed() -> void:
	if selected_item.is_empty() or selected_from_merchant:
		return

	if Sales.can_sell_item(selected_item):
		# Calculate sell value using the same logic as in _update_item_details
		var sell_value = selected_item.get("price", 0)  # Get full price first
		# Special cases for fixed-price items
		if selected_item.get("id", "") == "celestial_tear":
			sell_value = 50000  # Fixed price for Celestial Tear
		elif selected_item.get("id", "").begins_with("LORE_"):
			sell_value = 100000  # Fixed high price for Lore Fragments
		else:
			sell_value = sell_value / 2  # Half price for regular items

		# Add souls
		SoulsSystem.add_souls(sell_value)
		# Remove item from inventory
		var item_id = selected_item.get("id", "")
		Inventory.remove_item(item_id)
		# Emit trade completed signal
		SignalBus.trade_completed.emit(item_id, sell_value)
		# Update display
		_update_display()
		# Play sell sound
		SoundManager.play_sound(Sound.sell, "SFX")
		# Show sell feedback
		_show_sell_feedback()


func _show_sell_feedback() -> void:
	if !is_instance_valid(item_sprite):
		return

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_OUT)

	# Fade out effect
	tween.tween_property(item_sprite, "modulate:a", 0.0, 0.2)
	tween.tween_callback(_clear_item_details)


func _on_inventory_updated() -> void:
	if visible:
		_update_display()


func _on_trade_completed(_item_id: String, _souls_gained: int) -> void:
	if visible:
		_update_display()
