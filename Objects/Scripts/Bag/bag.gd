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
	
	# Set collision layer and mask for interaction using deferred calls
	set_deferred("collision_layer", C_Layers.LAYER_COLLECTIBLE)
	set_deferred("collision_mask", C_Layers.MASK_COLLECTIBLE | C_Layers.LAYER_WORLD)

	# Initialize raycasts with deferred calls
	var raycasts = [raycast_far_left, raycast_mid_left, raycast_near_left, 
					raycast_near_right, raycast_mid_right, raycast_far_right]
	
	# Validate that all raycasts exist
	for raycast in raycasts:
		if raycast != null:
			raycast.set_deferred("target_position", Vector2(0, 32))
			raycast.set_deferred("collision_mask", C_Layers.LAYER_WORLD)

	# Schedule position adjustment for next physics frame
	call_deferred("_schedule_position_adjustment")

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

func _schedule_position_adjustment() -> void:
	# Wait for next physics frame before checking position
	await get_tree().physics_frame
	_check_and_adjust_position()

func _check_and_adjust_position() -> void:
	# Ensure we're in a physics frame
	if Engine.is_in_physics_frame():
		var raycasts = [
			{"node": raycast_far_left, "offset": -30},
			{"node": raycast_mid_left, "offset": -20},
			{"node": raycast_near_left, "offset": -10},
			{"node": raycast_near_right, "offset": 10},
			{"node": raycast_mid_right, "offset": 20},
			{"node": raycast_far_right, "offset": 30}
		]

		# Find the furthest colliding raycast from center
		var furthest_colliding = null
		var max_distance = 0

		for raycast_data in raycasts:
			if raycast_data["node"] != null:
				raycast_data["node"].force_raycast_update()
				if raycast_data["node"].is_colliding():
					var distance = abs(raycast_data["offset"])
					if distance > max_distance:
						max_distance = distance
						furthest_colliding = raycast_data

		# Use set_deferred for position changes
		if furthest_colliding:
			set_deferred("position", Vector2(position.x + furthest_colliding["offset"], position.y))
	else:
		# If we're not in a physics frame, reschedule the check
		call_deferred("_schedule_position_adjustment")

func store_items(items: Dictionary) -> void:
	stored_items = items.duplicate(true)

func _cleanup_physics() -> void:
	# First, disable monitoring and monitorable states
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	# Disable all raycasts with deferred calls
	var raycasts = [raycast_far_left, raycast_mid_left, raycast_near_left, 
					raycast_near_right, raycast_mid_right, raycast_far_right]
	
	for raycast in raycasts:
		if raycast != null:
			raycast.set_deferred("enabled", false)
			raycast.set_deferred("collision_mask", 0)
	
	# Clear collision masks
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	
	# Schedule collision shape disabling for next frame
	if collision_shape:
		call_deferred("_disable_collision_shape")

func _disable_collision_shape() -> void:
	# Wait for physics to settle
	await get_tree().physics_frame
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	# Schedule free operation after physics state is cleaned up
	call_deferred("_safe_free")

func _safe_free() -> void:
	# Final cleanup and queue_free
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not stored_items.is_empty():
		# Calculate total value of recovered items
		var total_value: int = 0
		
		# Restore items to inventory and sum up total value
		for item_id in stored_items:
			var item_count = stored_items[item_id]
			# Ensure we're passing a dictionary with count for inventory
			var item_data = {"count": item_count} if item_count is int else item_count
			# Add item to inventory
			Inventory.add_item(item_id, item_data)
			# Add to total value
			total_value += item_count if item_count is int else item_data.get("count", 0)

		# Play recovery sound and effect
		SoundManager.play_sound(Sound.heal, "SFX")

		# Clear stored items
		stored_items.clear()

		# Emit signal that items were recovered using SignalBus
		SignalBus.souls_recovered.emit(total_value)

		# Start the cleanup process
		_cleanup_physics()
