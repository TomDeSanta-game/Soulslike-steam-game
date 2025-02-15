extends Node
class_name HealthSystem

# Base stats
var vigour: float = 0.0
var max_health: float = 0.0
var current_health: float = 0.0

# Conversion rate
const VIGOUR_TO_HEALTH_MULTIPLIER: float = 10.0

@warning_ignore("unused_signal")
signal _health_changed(new_health: float, max_health: float)
@warning_ignore("unused_signal")
signal _character_died


func _init(base_vigour: float = 0.0) -> void:
	set_vigour(base_vigour)


func set_vigour(new_vigour: float) -> void:
	vigour = new_vigour
	max_health = vigour * VIGOUR_TO_HEALTH_MULTIPLIER
	current_health = max_health
	emit_signal("_health_changed", current_health, max_health)


func get_health_percentage() -> float:
	return (current_health / max_health) * 100.0 if max_health > 0 else 0.0


# Added getter functions
func get_health() -> float:
	return current_health


func get_max_health() -> float:
	return max_health
