class_name TimeSystem extends Node

@export var date_time: DateTime
@export var ticks_per_second: int = 600

func _process(delta: float) -> void:
	date_time = DateTime.new()
	date_time.increase_by_sec(delta * ticks_per_second)
