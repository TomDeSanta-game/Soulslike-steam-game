extends Node

signal _health_changed(new_health: float, max_health: float)
signal _character_died

var _health_system: HealthSystem

func _init() -> void:
	_health_system = HealthSystem.new()

func set_vigour(value: int) -> void:
	_health_system.set_vigour(float(value))
	_health_changed.emit(_health_system.get_health(), _health_system.get_max_health())

func take_damage(amount: float) -> void:
	_health_system.current_health = max(0.0, _health_system.current_health - amount)
	_health_changed.emit(_health_system.get_health(), _health_system.get_max_health())
	
	if _health_system.current_health <= 0:
		_character_died.emit()

func heal(amount: float) -> void:
	_health_system.current_health = min(_health_system.max_health, _health_system.current_health + amount)
	_health_changed.emit(_health_system.get_health(), _health_system.get_max_health())

func get_health() -> float:
	return _health_system.get_health()

func get_max_health() -> float:
	return _health_system.get_max_health()

func get_health_percentage() -> float:
	return _health_system.get_health_percentage() 