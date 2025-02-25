class_name ProjectileBase extends Area2D

@export_group("Projectile Properties")
@export var speed: float = 200.0
@export var lifetime: float = 2.0
@export var damage: float = 10.0

var direction: Vector2 = Vector2.RIGHT
var shooter: Node2D = null
var elapsed_time: float = 0.0

# Death Things
@export var death_time: float = 0.5

@onready var death_timer: Timer = Timer.new()


func _ready() -> void:
	add_child(death_timer)
	death_timer.wait_time = death_time
	death_timer.one_shot = true
	death_timer.timeout.connect(_die)


func _process(delta: float) -> void:
	position += direction * speed * delta
	_check_lifetime(delta)


func initialize(pos: Vector2, dir: Vector2, proj_speed: float, proj_damage: float, duration: float, parent: Node2D) -> void:
	global_position = pos
	direction = dir.normalized()
	speed = proj_speed
	damage = proj_damage
	lifetime = duration
	shooter = parent
	elapsed_time = 0.0


func _check_lifetime(delta: float) -> void:
	elapsed_time += delta
	if elapsed_time >= lifetime:
		SignalBus.projectile_expired.emit(self)
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Hurtbox"):
		# Skip if the projectile hit its shooter
		if area.get_parent() == shooter:
			return
			
		SignalBus.projectile_hit.emit(self, area)
		_die()


func _die() -> void:
	queue_free()
