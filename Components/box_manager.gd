extends Node
class_name BoxManager

# Shape types for box creation
enum ShapeType {
	RECTANGLE,
	CIRCLE,
	CAPSULE
}

# Box creation settings
const DEFAULT_SETTINGS = {
	"hitbox": {
		"damage": 10.0,
		"knockback_force": 100.0,
		"knockback_duration": 0.2,
		"hit_stun_duration": 0.1,
		"one_shot": false,
		"debug_color": Color(1, 0, 0, 0.5)
	},
	"hurtbox": {
		"invincibility_duration": 0.5,
		"team": 0,
		"debug_color": Color(0, 1, 0, 0.5)
	}
}

# Create a hitbox with the given shape and settings
static func create_hitbox(shape_type: ShapeType, size: Vector2, settings: Dictionary = {}) -> HitboxComponent:
	var hitbox = HitboxComponent.new()
	
	# Apply default settings
	for key in DEFAULT_SETTINGS.hitbox:
		if settings.has(key):
			hitbox.set(key, settings[key])
		else:
			hitbox.set(key, DEFAULT_SETTINGS.hitbox[key])
	
	# Create and add collision shape
	var collision_shape = _create_collision_shape(shape_type, size)
	hitbox.add_child(collision_shape)
	
	return hitbox


# Create a hurtbox with the given shape and settings
static func create_hurtbox(shape_type: ShapeType, size: Vector2, settings: Dictionary = {}) -> HurtboxComponent:
	var hurtbox = HurtboxComponent.new()
	
	# Apply default settings
	for key in DEFAULT_SETTINGS.hurtbox:
		if settings.has(key):
			hurtbox.set(key, settings[key])
		else:
			hurtbox.set(key, DEFAULT_SETTINGS.hurtbox[key])
	
	# Create and add collision shape
	var collision_shape = _create_collision_shape(shape_type, size)
	hurtbox.add_child(collision_shape)
	
	return hurtbox


# Helper function to create collision shapes
static func _create_collision_shape(shape_type: ShapeType, size: Vector2) -> CollisionShape2D:
	var collision_shape = CollisionShape2D.new()
	
	match shape_type:
		ShapeType.RECTANGLE:
			var shape = RectangleShape2D.new()
			shape.extents = size / 2  # Size is halved for extents
			collision_shape.shape = shape
		
		ShapeType.CIRCLE:
			var shape = CircleShape2D.new()
			shape.radius = size.x / 2  # Use x component as diameter
			collision_shape.shape = shape
		
		ShapeType.CAPSULE:
			var shape = CapsuleShape2D.new()
			shape.radius = size.x / 2
			shape.height = size.y
			collision_shape.shape = shape
	
	return collision_shape


# Update box position and rotation
static func update_box_transform(box: Node2D, position: Vector2, rotation: float = 0.0) -> void:
	box.position = position
	box.rotation = rotation


# Create a hitbox for a weapon attack
static func create_weapon_hitbox(
	weapon_size: Vector2,
	damage: float,
	knockback_force: float = 100.0,
	effects: Array[String] = []
) -> HitboxComponent:
	return create_hitbox(
		ShapeType.CAPSULE,
		weapon_size,
		{
			"damage": damage,
			"knockback_force": knockback_force,
			"effects": effects,
			"one_shot": true
		}
	)


# Create a character hurtbox
static func create_character_hurtbox(
	character_size: Vector2,
	team: int = 0,
	invincibility_duration: float = 0.5
) -> HurtboxComponent:
	return create_hurtbox(
		ShapeType.CAPSULE,
		character_size,
		{
			"team": team,
			"invincibility_duration": invincibility_duration
		}
	)


# Create a projectile hitbox
static func create_projectile_hitbox(
	projectile_size: Vector2,
	damage: float,
	effects: Array[String] = []
) -> HitboxComponent:
	return create_hitbox(
		ShapeType.CIRCLE,
		projectile_size,
		{
			"damage": damage,
			"effects": effects,
			"one_shot": true
		}
	)


# Create an area of effect hitbox
static func create_aoe_hitbox(
	area_size: Vector2,
	damage: float,
	effects: Array[String] = []
) -> HitboxComponent:
	return create_hitbox(
		ShapeType.CIRCLE,
		area_size,
		{
			"damage": damage,
			"effects": effects,
			"knockback_force": 50.0,  # Reduced knockback for AoE
			"one_shot": false  # Can hit multiple times
		}
	) 