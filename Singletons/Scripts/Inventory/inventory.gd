extends Node

signal inventory_updated

var _items: Dictionary = {}

func add_item(item_id: String, item_data: Dictionary) -> void:
	if _items.has(item_id):
		_items[item_id].quantity += 1
	else:
		_items[item_id] = item_data
	
	inventory_updated.emit()

func remove_item(item_id: String) -> void:
	if _items.has(item_id):
		_items.erase(item_id)
		inventory_updated.emit()

func use_item(item_id: String) -> void:
	if _items.has(item_id):
		_items[item_id].quantity -= 1
		
		if _items[item_id].quantity <= 0:
			remove_item(item_id)
		else:
			inventory_updated.emit()

func get_items() -> Dictionary:
	return _items

func has_item(item_id: String) -> bool:
	return _items.has(item_id)

func get_item_quantity(item_id: String) -> int:
	if _items.has(item_id):
		return _items[item_id].quantity
	return 0 