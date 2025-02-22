extends Node

signal trade_completed(item_id: String, souls_gained: int)

const UNREAD_LORE_VALUE = 10000  # Souls value for unread lore

func get_item_value(item_data: Dictionary) -> int:
	# Return value based on item type and state
	if item_data.id == "LORE_001" and item_data.get("unread", false):
		return UNREAD_LORE_VALUE
	return 0

func can_sell_item(item_data: Dictionary) -> bool:
	# Check if item can be sold
	if item_data.id == "LORE_001":
		return item_data.get("unread", false)
	return true  # Other items can always be sold

func sell_item(item_id: String, item_data: Dictionary) -> void:
	var value = get_item_value(item_data)
	if value > 0:
		# Add souls to the player
		if has_node("/root/SoulsSystem"):
			var souls_system = get_node("/root/SoulsSystem")
			souls_system.add_souls(value)
		
		# Remove item from inventory
		if has_node("/root/Inventory"):
			var inventory = get_node("/root/Inventory")
			inventory.remove_item(item_id)
		
		# Emit trade completed signal
		trade_completed.emit(item_id, value) 