class_name ProjectileBase extends Area2D

signal projectile_expired
signal projectile_hit(area: Area2D)

@export_group("Projectile Properties")
@export var speed: float = 100.0
@export var lifetime: float = 5.0

var direction: Vector2 = Vector2.RIGHT
var elapsed_time: float = 0.0

# Death Things
@export var death_time: float

@onready var death_timer: Timer = Timer.new()


func _ready() -> void:
	add_child(death_timer)
	death_timer.wait_time = death_time
	death_timer.one_shot = true
	death_timer.timeout.connect(_die)


func _process(delta: float) -> void:
	position += direction * speed * delta
	_check_lifetime(delta)


func initialize(pos: Vector2, dir: Vector2, projectile_speed: float, duration: float) -> void:
	global_position = pos
	direction = dir.normalized()
	speed = projectile_speed
	lifetime = duration
	elapsed_time = 0.0


func _check_lifetime(delta: float) -> void:
	elapsed_time += delta
	if elapsed_time >= lifetime:
		projectile_expired.emit()
		# queue_free()


func _on_area_entered(area: Area2D) -> void:
	if Types.ObjectType.EXPLOSION:
		SoundManager.play_sound(Sound.explosion, "SFX")
		death_time = 1.4
		death_timer.start()
	projectile_hit.emit(area)


func _die() -> void:
	queue_free()
