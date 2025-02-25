extends Node2D

const OBJECT_SCENES: Dictionary = {
	Types.ObjectType.EXPLOSION:
	preload("res://Objects/Scenes/Projectiles/Explosion/explosion_proj.tscn"),
	Types.ObjectType.SHURIKEN:
	preload("res://Objects/Scenes/Traps/Shuriken_Trap/shuriken_trap.tscn")
}


func _ready() -> void:
	SignalBus.on_create_projectile.connect(_on_create_projectile)


func _process(_delta: float) -> void:
	pass


func _on_create_projectile(
	pos: Vector2, dir: Vector2, life_span: float, speed: float, ob_type: Types.ObjectType
):
	if !OBJECT_SCENES.has(ob_type):
		return

	# New Projectile
	var np: ProjectileBase = OBJECT_SCENES[ob_type].instantiate()

	np.setup(pos, dir, speed, life_span)
	call_deferred("add_child", np)
