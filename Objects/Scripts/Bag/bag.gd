extends Area2D

var stored_items: Dictionary = {}
var player = null
@onready var raycast_far_left: RayCast2D = $RayCastFarLeft
@onready var raycast_mid_left: RayCast2D = $RayCastMidLeft
@onready var raycast_near_left: RayCast2D = $RayCastNearLeft
@onready var raycast_near_right: RayCast2D = $RayCastNearRight
@onready var raycast_mid_right: RayCast2D = $RayCastMidRight
@onready var raycast_far_right: RayCast2D = $RayCastFarRight
@onready var bag_sprite: Sprite2D = $Sprite2D
@onready var light_sprite: Sprite2D = $LightSprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Shader properties
var shader_material: ShaderMaterial
const SHADER_PARAMS = {
	"glow_color": Color(1.0, 0.92, 0.75, 0.4),
	"inner_glow_color": Color(1.0, 0.8, 0.4, 0.6),
	"pulse_speed": 2.0,
	"sparkle_speed": 3.0,
	"edge_thickness": 1.0,
	"glow_intensity": 1.2,
	"inner_glow_intensity": 0.8,
	"sparkle_intensity": 0.5,
	"sparkle_density": 15.0
}

# Physics properties
var velocity: Vector2 = Vector2.ZERO
var gravity_force: float = 900.0  # Increased gravity for snappier falling
const TERMINAL_VELOCITY: float = 600.0  # Reduced terminal velocity for better control

func _ready() -> void:
	# Wait one frame to ensure all nodes are ready
	await get_tree().process_frame
	
	# Initialize shader
	_setup_shader()
	
	var players = get_tree().get_nodes_in_group("Player")
	player = players[0] if not players.is_empty() else null
	
	# Set collision layer and mask for interaction
	collision_layer = C_Layers.LAYER_COLLECTIBLE
	collision_mask = C_Layers.MASK_COLLECTIBLE | C_Layers.LAYER_WORLD

	# Initialize raycasts
	var raycasts = [raycast_far_left, raycast_mid_left, raycast_near_left, 
					raycast_near_right, raycast_mid_right, raycast_far_right]
	
	# Validate that all raycasts exist
	for raycast in raycasts:
		if raycast != null:
			raycast.target_position = Vector2(0, 32)  # Set downward raycast
			raycast.collision_mask = C_Layers.LAYER_WORLD

	# Check initial position and adjust if needed
	call_deferred("_check_and_adjust_position")

func _setup_shader() -> void:
	shader_material = ShaderMaterial.new()
	shader_material.shader = load("res://Shaders/Collectibles/bag_shader.gdshader")
	
	# Set all shader parameters
	for param in SHADER_PARAMS:
		set_shader_parameter(param, SHADER_PARAMS[param])
	
	# Apply shader to bag sprite
	bag_sprite.material = shader_material

# Shader control functions
func set_shader_parameter(param: String, value: Variant) -> void:
	if shader_material:
		shader_material.set_shader_parameter(param, value)

func set_glow_color(color: Color) -> void:
	set_shader_parameter("glow_color", color)

func set_inner_glow_color(color: Color) -> void:
	set_shader_parameter("inner_glow_color", color)

func set_pulse_speed(speed: float) -> void:
	set_shader_parameter("pulse_speed", speed)

func set_sparkle_speed(speed: float) -> void:
	set_shader_parameter("sparkle_speed", speed)

func set_edge_thickness(thickness: float) -> void:
	set_shader_parameter("edge_thickness", thickness)

func set_glow_intensity(intensity: float) -> void:
	set_shader_parameter("glow_intensity", intensity)

func set_inner_glow_intensity(intensity: float) -> void:
	set_shader_parameter("inner_glow_intensity", intensity)

func set_sparkle_intensity(intensity: float) -> void:
	set_shader_parameter("sparkle_intensity", intensity)

func set_sparkle_density(density: float) -> void:
	set_shader_parameter("sparkle_density", density)

func _physics_process(delta: float) -> void:
	# Apply gravity
	velocity.y = min(velocity.y + gravity_force * delta, TERMINAL_VELOCITY)

	# Check for ground collision
	var is_grounded = false
	var raycasts = [raycast_far_left, raycast_mid_left, raycast_near_left, 
					raycast_near_right, raycast_mid_right, raycast_far_right]
	
	for raycast in raycasts:
		if raycast != null and raycast.is_colliding():
			is_grounded = true
			var collision_point = raycast.get_collision_point()
			if position.y < collision_point.y:
				position.y = collision_point.y - 16  # Adjust based on your sprite size
				velocity.y = 0
			break

	# Update position
	if not is_grounded:
		position += velocity * delta


func _check_and_adjust_position() -> void:
	var raycasts = [
		{"node": raycast_far_left, "offset": -30},
		{"node": raycast_mid_left, "offset": -20},
		{"node": raycast_near_left, "offset": -10},
		{"node": raycast_near_right, "offset": 10},
		{"node": raycast_mid_right, "offset": 20},
		{"node": raycast_far_right, "offset": 30}
	]

	# Force update all raycasts
	for raycast_data in raycasts:
		if raycast_data["node"] != null:
			raycast_data["node"].force_raycast_update()

	# Find the furthest colliding raycast from center
	var furthest_colliding = null
	var max_distance = 0

	for raycast_data in raycasts:
		if raycast_data["node"] != null and raycast_data["node"].is_colliding():
			var distance = abs(raycast_data["offset"])
			if distance > max_distance:
				max_distance = distance
				furthest_colliding = raycast_data

	# Teleport to the furthest colliding raycast's position
	if furthest_colliding:
		position.x += furthest_colliding["offset"]


func store_items(items: Dictionary) -> void:
	stored_items = items.duplicate(true)


func _cleanup_physics() -> void:
	# Disable all raycasts
	var raycasts = [raycast_far_left, raycast_mid_left, raycast_near_left, 
					raycast_near_right, raycast_mid_right, raycast_far_right]
	
	for raycast in raycasts:
		if raycast != null:
			raycast.enabled = false
			raycast.collision_mask = 0
	
	# Disable collision shape
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
		
	# Clear collision masks
	collision_layer = 0
	collision_mask = 0


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not stored_items.is_empty():
		# Restore items to inventory
		for item_id in stored_items.keys():
			Inventory.add_item(item_id, stored_items[item_id])

		# Play recovery sound and effect
		SoundManager.play_sound(Sound.heal, "SFX")

		# Clear stored items
		stored_items.clear()

		# Emit signal that items were recovered using SignalBus
		SignalBus.souls_recovered.emit(0)  # Using existing signal, or add a specific one in SignalBus if needed

		# Clean up physics before freeing
		_cleanup_physics()
		
		# Queue free after cleanup
		queue_free()
