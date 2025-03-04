extends Node

signal inventory_state_changed(is_any_open: bool)

var _current_open_inventory: String = ""

func is_any_inventory_open() -> bool:
	return _current_open_inventory != ""

func open_inventory(inventory_name: String) -> bool:
	if is_any_inventory_open():
		return false
	_current_open_inventory = inventory_name
	inventory_state_changed.emit(true)
	return true

func close_inventory(inventory_name: String) -> void:
	if _current_open_inventory == inventory_name:
		_current_open_inventory = ""
		inventory_state_changed.emit(false) 