extends Node

signal inventory_updated

var items: Dictionary = {}

func add_item(item_id: String, item_data: Dictionary) -> void:
	if not items.has(item_id):
		items[item_id] = item_data
	else:
		items[item_id].quantity += 1
	
	inventory_updated.emit()

func remove_item(item_id: String) -> void:
	if items.has(item_id):
		items[item_id].quantity -= 1
		if items[item_id].quantity <= 0:
			items.erase(item_id)
		inventory_updated.emit()

func get_items() -> Dictionary:
	return items

func has_item(item_id: String) -> bool:
	return items.has(item_id)

func get_item_quantity(item_id: String) -> int:
	if items.has(item_id):
		return items[item_id].quantity
	return 0 