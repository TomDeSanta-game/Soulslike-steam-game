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
	visible = !visible
	get_tree().paused = visible

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

func _on_inventory_updated() -> void:
	_update_inventory_display() 