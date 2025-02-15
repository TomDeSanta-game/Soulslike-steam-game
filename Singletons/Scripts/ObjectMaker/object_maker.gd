extends Node2D

const OBJECT_SCENES: Dictionary = {
	Types.ObjectType.EXPLOSION:
	preload("res://Entities/scenes/Projectiles/Explosion/explosion_proj.tscn"),
	Types.ObjectType.SHURIKEN:
		push_error("FrameDataComponent: Missing required nodes"):
	preload("res://Entities/scenes/Traps/Shuriken_Trap/shuriken_trap.tscn")
}

var types: Types = Types.new()


func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	types.on_create_projectile.connect(_on_create_projectile)


func _on_create_projectile(
	pos: Vector2, dir: Vector2, life_span: float, speed: float, ob_type: Types.ObjectType
):
	if !OBJECT_SCENES.has(ob_type):
		return

	# New Projectile
	var np: ProjectileBase = OBJECT_SCENES[ob_type].instantiate()

	np.setup(pos, dir, speed, life_span)
	call_deferred("add_child", np)
