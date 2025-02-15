class_name Shooter extends Node2D

@export var shoot_timer: Timer

@export var speed: float = 50.0
@export var life_span: float = 10.0
@export var bullet_key: Types.ObjectType
@export var shoot_delay: float = 1.0

var can_shoot: bool = true

@onready var types: Types = Types.new()


func _ready() -> void:
	if shoot_timer:
		shoot_timer.wait_time = shoot_delay


func shoot(dir: Vector2) -> void:
	if can_shoot == false:
		return

	can_shoot = false

	types.on_create_projectile.emit(global_position, dir, life_span, speed, bullet_key)

	shoot_timer.start()


func _on_shoot_timer_timeout() -> void:
	can_shoot = true
