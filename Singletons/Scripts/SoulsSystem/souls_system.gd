extends Node

# Current amount of souls
var _current_souls: int = 0

# Lost souls data
var _lost_souls: Dictionary = {
	"amount": 0,
	"position": Vector2.ZERO
}

# Constants
const MIN_SOULS: int = 0
const MAX_SOULS: int = 999999999  # 999 million souls cap

# Get current souls amount
func get_souls() -> int:
	return _current_souls

# Add souls (e.g., from defeating enemies)
func add_souls(amount: int) -> void:
	if amount <= 0:
		return
		
	var new_amount = min(_current_souls + amount, MAX_SOULS)
	if new_amount != _current_souls:
		_current_souls = new_amount
		SignalBus.souls_changed.emit(_current_souls)

# Spend souls (e.g., for leveling up or buying items)
func spend_souls(amount: int) -> bool:
	if amount <= 0 or amount > _current_souls:
		return false
		
	_current_souls -= amount
	SignalBus.souls_changed.emit(_current_souls)
	return true

# Called when player dies - creates a souls drop at the death location
func drop_souls(position: Vector2) -> void:
	if _current_souls <= 0:
		return
		
	_lost_souls = {
		"amount": _current_souls,
		"position": position
	}
	
	var lost_amount = _current_souls
	_current_souls = 0
	SignalBus.souls_changed.emit(_current_souls)
	SignalBus.souls_lost.emit(lost_amount)

# Recover previously lost souls
func recover_souls() -> void:
	if _lost_souls.amount <= 0:
		return
		
	add_souls(_lost_souls.amount)
	SignalBus.souls_recovered.emit(_lost_souls.amount)
	_lost_souls = {
		"amount": 0,
		"position": Vector2.ZERO
	}

# Get the position of lost souls
func get_lost_souls_position() -> Vector2:
	return _lost_souls.position

# Get the amount of lost souls
func get_lost_souls_amount() -> int:
	return _lost_souls.amount

# Check if there are any lost souls to recover
func has_lost_souls() -> bool:
	return _lost_souls.amount > 0

# Clear all souls (useful for new game or testing)
func clear_souls() -> void:
	_current_souls = 0
	_lost_souls = {
		"amount": 0,
		"position": Vector2.ZERO
	}
	SignalBus.souls_changed.emit(_current_souls)

# Format souls amount for display (e.g., "1,234,567")
func format_souls(amount: int) -> String:
	var formatted = ""
	var str_amount = str(amount)
	var length = str_amount.length()
	var comma_count = 0
	
	for i in range(length):
		if i > 0 and (length - i) % 3 == 0:
			formatted = "," + formatted
		formatted = str_amount[length - 1 - i] + formatted
	
	return formatted 