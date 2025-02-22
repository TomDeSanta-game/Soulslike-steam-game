class_name MerchantMenu
extends Control

@onready var merchant_grid: GridContainer = $Panel/MerchantInventory/ItemGrid
@onready var player_grid: GridContainer = $Panel/PlayerInventory/ItemGrid
@onready var item_slot_scene: PackedScene = preload("res://UI/Scenes/inventory_slot.tscn")
@onready var item_name_label: Label = $Panel/ItemDetails/ItemName
@onready var item_description_label: Label = $Panel/ItemDetails/ItemDescription
@onready var price_label: Label = $Panel/ItemDetails/Price
@onready var buy_button: Button = $Panel/ItemDetails/BuyButton
@onready var sell_button: Button = $Panel/ItemDetails/SellButton

var selected_item: Dictionary = {}
var merchant_inventory: Dictionary = {}
var selected_from_merchant: bool = false

func _ready() -> void:
	# Hide menu by default
	visible = false
	
	# Connect signals
	buy_button.pressed.connect(_on_buy_pressed)
	sell_button.pressed.connect(_on_sell_pressed)
	
	# Connect to inventory updated signal
	Inventory.inventory_updated.connect(_on_inventory_updated)
	
	# Initialize merchant inventory
	_initialize_merchant_inventory()
	
	# Initial update
	_update_display()

func _initialize_merchant_inventory() -> void:
	merchant_inventory = {
		"celestial_tear": {
			"id": "celestial_tear",
			"name": "Celestial Tear",
			"description": "A divine crystallized tear from the heavens, radiating pure celestial energy. Restores full health and stamina when used.",
			"price": 50000,  # Same as SOULS_REWARD from celestial_tear.gd
			"texture": load("res://assets/Sprite-0003.png"),
			"use_function": "use_celestial_tear"
		},
		"LORE_001": {
			"id": "LORE_001",
			"name": "Ancient Fragment",
			"description": "A Piece Of Knowledge From The Old Era",
			"price": 100000,  # Set a high price for lore fragments
			"type": "lore",
			"texture": load("res://assets/cover.png"),  # Replace with actual lore texture path
			"use_function": "read_lore",
			"has_been_read": false,
			"unread": true
		}
	}

func toggle_merchant() -> void:
	visible = !visible
	get_tree().paused = visible
	if visible:
		_update_display()

func _update_display() -> void:
	_update_merchant_grid()
	_update_player_grid()
	_clear_item_details()

func _update_merchant_grid() -> void:
	# Clear existing slots
	for child in merchant_grid.get_children():
		child.queue_free()
	
	# Add slots for each merchant item
	for item_id in merchant_inventory:
		var item_data: Dictionary = merchant_inventory[item_id]
		var slot: Node = item_slot_scene.instantiate()
		merchant_grid.add_child(slot)
		slot.set_item(item_data)
		if slot.has_signal("item_selected"):
			slot.item_selected.connect(_on_merchant_item_selected.bind(item_data))

func _update_player_grid() -> void:
	# Clear existing slots
	for child in player_grid.get_children():
		child.queue_free()
	
	# Add slots for each player item
	for item_id in Inventory.get_items():
		var item_data: Dictionary = Inventory.get_items()[item_id]
		var slot: Node = item_slot_scene.instantiate()
		player_grid.add_child(slot)
		slot.set_item(item_data)
		if slot.has_signal("item_selected"):
			slot.item_selected.connect(_on_player_item_selected.bind(item_data))

func _on_merchant_item_selected(item_data: Dictionary) -> void:
	selected_item = item_data
	selected_from_merchant = true
	_update_item_details()

func _on_player_item_selected(item_data: Dictionary) -> void:
	selected_item = item_data
	selected_from_merchant = false
	_update_item_details()

func _update_item_details() -> void:
	if selected_item.is_empty():
		_clear_item_details()
		return
	
	item_name_label.text = selected_item.name
	item_description_label.text = selected_item.description
	price_label.text = str(selected_item.price) + " souls"
	
	buy_button.visible = selected_from_merchant
	sell_button.visible = !selected_from_merchant

func _clear_item_details() -> void:
	item_name_label.text = ""
	item_description_label.text = ""
	price_label.text = ""
	buy_button.visible = false
	sell_button.visible = false
	selected_item = {}

func _on_buy_pressed() -> void:
	if selected_item.is_empty() or !selected_from_merchant:
		return
	
	var price: int = selected_item.price
	if Inventory.get_souls() >= price:
		# Deduct souls
		Inventory.remove_souls(price)
		# Add item to player inventory with all its data
		Inventory.add_item(selected_item.id, selected_item)
		# Update display
		_update_display()

func _on_sell_pressed() -> void:
	if selected_item.is_empty() or selected_from_merchant:
		return
	
	var price: int = selected_item.price
	if price:
		# Add souls (sell for half the buy price)
		Inventory.add_souls(price / 2)
		# Remove item from player inventory
		Inventory.remove_item(selected_item.id)
		# Update display
		_update_display()

func _on_inventory_updated() -> void:
	if visible:
		_update_display() 