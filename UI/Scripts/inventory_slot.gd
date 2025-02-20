class_name InventorySlot
extends Panel

signal item_used(item_data: Dictionary)

@onready var texture_rect = $TextureRect
@onready var quantity_label = $QuantityLabel
@onready var use_button = $UseButton
@onready var hide_timer = Timer.new()
@onready var item_container = $ItemContainer

const BUTTON_VISIBLE_TIME = 1.5  # Time in seconds to keep button visible
const CELESTIAL_TEAR_SCENE = preload("res://Objects/Scenes/Collectibles/CelestialTear/celestial_tear.tscn")

var item_data: Dictionary = {}
var is_hovering: bool = false
var tear_instance = null

func _ready() -> void:
	# Hide use button initially
	use_button.hide()
	use_button.text = "EAT"

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

func set_item(data: Dictionary) -> void:
	print("Setting item with data: ", data)  # Debug print
	item_data = data
	
	# Clear existing tear instance if any
	if tear_instance:
		tear_instance.queue_free()
		tear_instance = null
	
	# If this is a celestial tear, instantiate the scene
	if data.id == "celestial_tear":
		print("Creating celestial tear instance")  # Debug print
		tear_instance = CELESTIAL_TEAR_SCENE.instantiate()
		item_container.add_child(tear_instance)
		
		# Adjust the size and position of the tear instance
		if tear_instance is Node2D:
			tear_instance.scale = Vector2(4.0, 4.0)  # Make it 4x larger
			tear_instance.position = Vector2(64, 64)  # Center in the larger slot
		
		# Hide the default texture
		texture_rect.hide()
	else:
		texture_rect.texture = data.texture
		texture_rect.show()

	if data.quantity > 1:
		quantity_label.text = str(data.quantity)
		quantity_label.show()
	else:
		quantity_label.hide()

func _on_mouse_entered() -> void:
	is_hovering = true
	print("Mouse entered, item_data: ", item_data)  # Debug print
	if item_data.get("id") == "celestial_tear":
		print("Showing eat button")  # Debug print
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
	if item_data.is_empty():
		return

	# Emit signal to handle item usage
	item_used.emit(item_data)

	# Update quantity
	item_data.quantity -= 1

	if item_data.quantity > 0:
		# Update display
		set_item(item_data)
	else:
		# Clear slot if no items left
		queue_free()
