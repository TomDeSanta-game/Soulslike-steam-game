class_name TrapBase extends Area2D

signal trap_expired
signal trap_hit(area: Area2D)

@export_group("Trap Properties")
@export var speed: float = 100.0
@export var lifetime: float = 5.0

var direction: Vector2 = Vector2.DOWN
var elapsed_time: float = 0.0


func _process(delta: float) -> void:
	position += direction * speed * delta
	_check_lifetime(delta)


func initialize(pos: Vector2, dir: Vector2, trap_speed: float, duration: float) -> void:
	global_position = pos
	direction = dir.normalized()
	speed = trap_speed
	lifetime = duration
	elapsed_time = 0.0


func _check_lifetime(delta: float) -> void:
	elapsed_time += delta
	if elapsed_time >= lifetime:
		trap_expired.emit()
		# queue_free()


func _on_area_entered(area: Area2D) -> void:
	trap_hit.emit(area)
	_die()


func _die() -> void:
	queue_free()
