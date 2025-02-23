class_name InventoryUI
extends Control

@onready var grid_container: GridContainer = $Panel/GridContainer
@onready var item_slot_scene: PackedScene = preload("res://UI/Scenes/inventory_slot.tscn")

func _ready() -> void:
	# Connect to inventory updated signal
	Inventory.inventory_updated.connect(_on_inventory_updated)
	
	# Initial update
	_update_inventory_display()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("INVENTORY"):
		toggle_inventory()

func toggle_inventory() -> void:
	if visible:
		visible = false
		get_tree().paused = false
		InventoryStateManager.close_inventory("inventory")
	else:
		if InventoryStateManager.open_inventory("inventory"):
			visible = true
			get_tree().paused = true
			_update_inventory_display()

func _update_inventory_display() -> void:
	# Clear existing slots
	for child in grid_container.get_children():
		child.queue_free()
	
	# Add slots for each item
	for item_id in Inventory.get_items():
		var item_data: Dictionary = Inventory.get_items()[item_id]
		var slot: Node = item_slot_scene.instantiate()
		grid_container.add_child(slot)
		slot.set_item(item_data)
		# Connect the item_used signal
		if slot.has_signal("item_used"):
			slot.item_used.connect(_on_item_used)

func _on_inventory_updated() -> void:
	_update_inventory_display()

func _on_item_used(item_data: Dictionary) -> void:
	if not item_data.has("use_function") or not item_data.has("id"):
		return
		
	# Get player reference
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() == 0:
		return
		
	var player = players[0]
	
	# Handle celestial tear usage
	if item_data.id == "celestial_tear" and player.has_method("use_celestial_tear"):
		# Update inventory first
		Inventory.use_item(item_data.id)
		
		# Use the item
		player.use_celestial_tear()
		
		# Update display
		_update_inventory_display()
		
		# Unpause the game
		get_tree().paused = false 
