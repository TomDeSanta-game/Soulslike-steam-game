class_name MerchantMenu
extends Control

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
	"normal": {
		"bg_color": Color(0.2, 0.2, 0.2, 0.8),
		"border_color": Color(0.4, 0.4, 0.4, 1.0),
		"border_width": 2,
		"corner_radius": 8
	},
	"highlighted": {
		"bg_color": Color(0.3, 0.7, 0.3, 1.0),
		"border_color": Color(0.4, 1.0, 0.4, 1.0),
		"border_width": 3,
		"corner_radius": 8
	},
	"disabled": {
		"bg_color": Color(0.5, 0.1, 0.1, 0.8),
		"border_color": Color(0.8, 0.2, 0.2, 1.0),
		"border_width": 2,
		"corner_radius": 8
	}
}

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Setup insufficient souls label
	insufficient_souls_label.visible = false
	insufficient_souls_label.add_theme_font_size_override("font_size", 48)  # Much larger
	insufficient_souls_label.add_theme_color_override("font_color", Color(0.8, 0, 0))  # Deep red
	insufficient_souls_label.modulate = Color(1, 1, 1, 0)  # Start transparent
	
	# Move label to bottom center of screen
	insufficient_souls_label.anchor_left = 0.5
	insufficient_souls_label.anchor_right = 0.5
	insufficient_souls_label.anchor_top = 1.0
	insufficient_souls_label.anchor_bottom = 1.0
	insufficient_souls_label.offset_left = -200
	insufficient_souls_label.offset_right = 200
	insufficient_souls_label.offset_bottom = -50
	insufficient_souls_label.offset_top = -100
	insufficient_souls_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	insufficient_souls_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	# Disconnect any existing connections first
	if buy_button.pressed.is_connected(_on_buy_pressed):
		buy_button.pressed.disconnect(_on_buy_pressed)
	if sell_button.pressed.is_connected(_on_sell_pressed):
		sell_button.pressed.disconnect(_on_sell_pressed)
	if close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.disconnect(_on_close_pressed)
	if Inventory.inventory_updated.is_connected(_on_inventory_updated):
		Inventory.inventory_updated.disconnect(_on_inventory_updated)
	if Sales.trade_completed.is_connected(_on_trade_completed):
		Sales.trade_completed.disconnect(_on_trade_completed)
	
	# Connect signals
	buy_button.pressed.connect(_on_buy_pressed)
	sell_button.pressed.connect(_on_sell_pressed)
	close_button.pressed.connect(_on_close_pressed)
	Inventory.inventory_updated.connect(_on_inventory_updated)
	Sales.trade_completed.connect(_on_trade_completed)
	
	# Setup button styles
	_setup_button_styles()
	
	# Initialize sprite animation player
	sprite_animation_player = AnimationPlayer.new()
	item_sprite.add_child(sprite_animation_player)

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

func _setup_item_sprite(item_data: Dictionary) -> void:
	if !is_instance_valid(item_sprite):
		return
		
	# Clear any existing children and reset
	for child in item_sprite.get_children():
		if is_instance_valid(child):
			child.queue_free()
	
	item_sprite.texture = null
	item_sprite.material = null
	item_sprite.custom_minimum_size = Vector2(150, 150)
	
	if item_data.has("scene"):
		# For scene-based items (like Celestial Tear)
		var instance = item_data.scene.instantiate()
		item_sprite.add_child(instance)
		if instance is Node2D:
			instance.position = item_sprite.size / 2
			instance.scale = Vector2(4, 4)
	elif item_data.has("frames"):
		# For animated sprites
		var sprite = AnimatedSprite2D.new()
		sprite.sprite_frames = item_data.frames
		sprite.centered = true
		sprite.play("default")
		item_sprite.add_child(sprite)
		
		# Position and scale the sprite properly
		sprite.position = item_sprite.size / 2
		sprite.scale = Vector2(3, 3)  # Larger scale
		
		# Ensure it's visible and playing
		sprite.show()
		sprite.playing = true
		
		# Add a subtle rotation animation
		var rotation_anim = Animation.new()
		var track_idx = rotation_anim.add_track(Animation.TYPE_VALUE)
		rotation_anim.track_set_path(track_idx, ^".:rotation")
		rotation_anim.length = 2.0
		rotation_anim.track_insert_key(track_idx, 0.0, 0.0)
		rotation_anim.track_insert_key(track_idx, 2.0, PI * 2)
		rotation_anim.loop_mode = Animation.LOOP_LINEAR
		
		var anim_player = AnimationPlayer.new()
		sprite.add_child(anim_player)
		anim_player.add_animation("rotate", rotation_anim)
		anim_player.play("rotate")
	elif item_data.has("texture"):
		item_sprite.texture = item_data.texture
		item_sprite.expand_mode = 1
		item_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Handle material/shader
	if item_data.has("material"):
		var mat = item_data.material.duplicate()
		item_sprite.material = mat
		if mat is ShaderMaterial:
			mat.set_shader_parameter("time_elapsed", 0.0)
			mat.set_shader_parameter("effect_progress", 0.0)
			
			# Create a timer to update shader time
			var timer = Timer.new()
			item_sprite.add_child(timer)
			timer.wait_time = 0.016  # ~60 FPS
			timer.timeout.connect(func(): mat.set_shader_parameter("time_elapsed", Time.get_ticks_msec() / 1000.0))
			timer.start()
	elif item_data.has("shader"):
		var mat = ShaderMaterial.new()
		mat.shader = item_data.shader
		item_sprite.material = mat
		
		# Create a timer to update shader time
		var timer = Timer.new()
		item_sprite.add_child(timer)
		timer.wait_time = 0.016  # ~60 FPS
		timer.timeout.connect(func(): mat.set_shader_parameter("time_elapsed", Time.get_ticks_msec() / 1000.0))
		timer.start()

func _update_button_state(button: Button, visible: bool, disabled: bool, text: String = "") -> void:
	if !is_instance_valid(button):
		return
		
	button.visible = visible
	button.disabled = disabled
	if text:
		button.text = text
	
	# Show/hide insufficient souls label
	if is_instance_valid(insufficient_souls_label):
		insufficient_souls_label.visible = disabled and visible and selected_from_merchant

func _on_buy_pressed() -> void:
	if selected_item.is_empty() or !selected_from_merchant:
		return
	
	var price: int = selected_item.price
	if SoulsSystem.get_souls() >= price:
		var quantity = merchant_inventory[selected_item.id].get("quantity", 0)
		if quantity > 0:
			# Try to spend souls
			if SoulsSystem.spend_souls(price):
				# Add item to player inventory
				Inventory.add_item(selected_item.id, selected_item)
				# Update merchant inventory
				merchant_inventory[selected_item.id].quantity -= 1
				if merchant_inventory[selected_item.id].quantity <= 0:
					merchant_inventory.erase(selected_item.id)
				# Update display
				_update_display()
				# Play purchase sound
				SoundManager.play_sound(Sound.collect, "SFX")
				# Show success feedback
				_show_purchase_feedback()
			else:
				# Show insufficient souls feedback if spend failed
				_show_insufficient_souls_feedback()
	else:
		# Show insufficient souls feedback
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
		
	insufficient_souls_label.visible = true
	insufficient_souls_label.text = "NOT ENOUGH SOULS!"
	
	# Cancel any existing tweens
	var existing_tweens = get_tree().get_nodes_in_group("insufficient_souls_tween")
	for tween in existing_tweens:
		if tween is Tween:
			tween.kill()
	
	# Create new tween
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	# Fade in with bounce
	insufficient_souls_label.modulate = Color(1, 0, 0, 0)  # Start transparent and red
	tween.tween_property(insufficient_souls_label, "modulate", Color(1, 0, 0, 1), 0.3)
	
	# Add shake effect
	var original_pos = insufficient_souls_label.position
	for i in range(5):
		tween.tween_property(insufficient_souls_label, "position:x", original_pos.x - 10, 0.05)
		tween.tween_property(insufficient_souls_label, "position:x", original_pos.x + 10, 0.05)
	tween.tween_property(insufficient_souls_label, "position:x", original_pos.x, 0.05)
	
	# Pulse effect
	for i in range(2):
		tween.tween_property(insufficient_souls_label, "modulate:a", 0.5, 0.5)
		tween.tween_property(insufficient_souls_label, "modulate:a", 1.0, 0.5)
	
	# Fade out
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(insufficient_souls_label):
		tween = create_tween()
		tween.tween_property(insufficient_souls_label, "modulate:a", 0.0, 0.5)
		await tween.finished
		insufficient_souls_label.visible = false

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
			if is_inside_tree() and get_tree():  # Check if we have access to the tree
				get_tree().paused = true
			_update_display()

func _on_close_pressed() -> void:
	if !is_instance_valid(self) or !is_inside_tree():
		return
		
	visible = false
	if is_inside_tree() and get_tree():  # Check if we have access to the tree
		get_tree().paused = false
	InventoryStateManager.close_inventory("merchant")
	_clear_item_details()

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
	if !is_instance_valid(item_name_label) or !is_instance_valid(item_description_label) or !is_instance_valid(price_label):
		return
		
	if selected_item.is_empty():
		_clear_item_details()
		return
	
	# Setup sprite and animations
	_setup_item_sprite(selected_item)
	
	# Update text
	if is_instance_valid(item_name_label):
		item_name_label.text = selected_item.name
	if is_instance_valid(item_description_label):
		item_description_label.text = selected_item.description
	
	if selected_from_merchant:
		var price = selected_item.price
		var can_afford = SoulsSystem.get_souls() >= price
		if is_instance_valid(price_label):
			price_label.text = "Buy for %s souls" % SoulsSystem.format_souls(price)
		if is_instance_valid(buy_button) and is_instance_valid(sell_button):
			buy_button.visible = true
			sell_button.visible = false
			_update_button_state(buy_button, true, !can_afford, "Buy for %s souls" % SoulsSystem.format_souls(price))
	else:
		var sell_value = Sales.get_item_value(selected_item) if selected_item.id == "LORE_001" else selected_item.price / 2
		if is_instance_valid(price_label):
			price_label.text = "Sell for %s souls" % SoulsSystem.format_souls(sell_value)
		if is_instance_valid(buy_button) and is_instance_valid(sell_button):
			buy_button.visible = false
			sell_button.visible = true
			_update_button_state(sell_button, true, not Sales.can_sell_item(selected_item), "Sell for %s souls" % SoulsSystem.format_souls(sell_value))

func _clear_item_details() -> void:
	if !is_instance_valid(item_sprite) or !is_instance_valid(item_name_label) or !is_instance_valid(item_description_label) or !is_instance_valid(price_label):
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
		var sell_value = Sales.get_item_value(selected_item) if selected_item.id == "LORE_001" else selected_item.price / 2
		
		# Add souls
		SoulsSystem.add_souls(sell_value)
		# Remove item from inventory
		Inventory.remove_item(selected_item.id)
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

func _on_trade_completed() -> void:
	if visible:
		_update_display()