extends Node

signal inventory_updated

var _items: Dictionary = {}

func add_item(item_id: String, item_data: Dictionary) -> void:
	if _items.has(item_id):
		# If item exists, increment quantity
		_items[item_id]["quantity"] = _items[item_id].get("quantity", 1) + 1
	else:
		# If new item, add it with quantity 1
		var new_item = item_data.duplicate()
		new_item["quantity"] = 1
		_items[item_id] = new_item
	inventory_updated.emit()

func remove_item(item_id: String) -> void:
	if _items.has(item_id):
		# Decrease quantity
		_items[item_id]["quantity"] = _items[item_id].get("quantity", 1) - 1
		# Remove item if quantity reaches 0
		if _items[item_id]["quantity"] <= 0:
			_items.erase(item_id)
		inventory_updated.emit()

func use_item(item_id: String) -> void:
	if _items.has(item_id):
		remove_item(item_id)

func get_items() -> Dictionary:
	return _items

func has_item(item_id: String) -> bool:
	return _items.has(item_id)

func clear_inventory() -> void:
	_items.clear()
	inventory_updated.emit()
