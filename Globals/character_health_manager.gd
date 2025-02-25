extends Node

var _health_system: HealthSystem

func _init() -> void:
	_health_system = HealthSystem.new()

func set_vigour(value: int) -> void:
	_health_system.set_vigour(float(value))
	SignalBus.health_changed.emit(_health_system.get_health(), _health_system.get_max_health())

func take_damage(amount: float) -> void:
	_health_system.current_health = max(0.0, _health_system.current_health - amount)
	SignalBus.health_changed.emit(_health_system.get_health(), _health_system.get_max_health())
	
	if _health_system.current_health <= 0:
		SignalBus.character_died.emit()

func heal(amount: float) -> void:
	_health_system.current_health = min(_health_system.max_health, _health_system.current_health + amount)
	SignalBus.health_changed.emit(_health_system.get_health(), _health_system.get_max_health())

func get_health() -> float:
	return _health_system.get_health()

func get_max_health() -> float:
	return _health_system.get_max_health()

func get_health_percentage() -> float:
	var health = _health_system.get_health()
	var max_health = _health_system.get_max_health()
	return (health / max_health) * 100.0 if max_health > 0 else 0.0 
