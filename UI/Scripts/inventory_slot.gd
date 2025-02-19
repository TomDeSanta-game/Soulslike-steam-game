extends Panel

signal item_used(item_data: Dictionary)

@onready var texture_rect = $TextureRect
@onready var quantity_label = $QuantityLabel
@onready var use_button = $UseButton
@onready var hide_timer = Timer.new()

const BUTTON_VISIBLE_TIME = 1.5  # Time in seconds to keep button visible

var item_data: Dictionary = {}
var is_hovering: bool = false


func _ready() -> void:
	# Hide use button initially
	use_button.hide()
	use_button.text = "EAT"

	# Setup timer
	hide_timer.one_shot = true
	hide_timer.wait_time = BUTTON_VISIBLE_TIME
	hide_timer.timeout.connect(_on_hide_timer_timeout)
	add_child(hide_timer)

	# Connect signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	use_button.pressed.connect(_on_use_button_pressed)
	use_button.mouse_entered.connect(_on_button_mouse_entered)
	use_button.mouse_exited.connect(_on_button_mouse_exited)


func set_item(data: Dictionary) -> void:
	item_data = data
	texture_rect.texture = data.texture

	if data.quantity > 1:
		quantity_label.text = str(data.quantity)
		quantity_label.show()
	else:
		quantity_label.hide()


func _on_mouse_entered() -> void:
	is_hovering = true
	if item_data.has("use_function"):
		use_button.show()
		if hide_timer and is_instance_valid(hide_timer) and hide_timer.is_inside_tree():
			hide_timer.stop()  # Stop any existing timer


func _on_mouse_exited() -> void:
	is_hovering = false
	if hide_timer and is_instance_valid(hide_timer) and hide_timer.is_inside_tree():
		hide_timer.start()  # Start the timer to hide the button


func _on_button_mouse_entered() -> void:
	is_hovering = true
	if hide_timer and is_instance_valid(hide_timer) and hide_timer.is_inside_tree():
		hide_timer.stop()  # Stop the timer when hovering over button


func _on_button_mouse_exited() -> void:
	is_hovering = false
	if hide_timer and is_instance_valid(hide_timer) and hide_timer.is_inside_tree():
		hide_timer.start()  # Start the timer when leaving button


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
