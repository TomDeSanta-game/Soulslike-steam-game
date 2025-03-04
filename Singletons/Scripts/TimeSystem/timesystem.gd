@tool
extends Node

const GameDateTimeClass = preload("res://Singletons/Scripts/DateTime/datetime.gd")
@export var date_time: GameDateTimeClass
@export var ticks_per_second: int = 600

func _ready() -> void:
	date_time = GameDateTimeClass.new()

func _process(delta: float) -> void:
	date_time.increase_by_sec(delta * ticks_per_second)
