extends Area2D

signal items_recovered

var stored_items: Dictionary = {}
var player = null
@onready var raycast_far_left: RayCast2D = $RayCastFarLeft
@onready var raycast_mid_left: RayCast2D = $RayCastMidLeft
@onready var raycast_near_left: RayCast2D = $RayCastNearLeft
@onready var raycast_near_right: RayCast2D = $RayCastNearRight
@onready var raycast_mid_right: RayCast2D = $RayCastMidRight
@onready var raycast_far_right: RayCast2D = $RayCastFarRight

# Physics properties
var velocity: Vector2 = Vector2.ZERO
var gravity_force: float = 900.0  # Increased gravity for snappier falling
const TERMINAL_VELOCITY: float = 600.0  # Reduced terminal velocity for better control


func _ready() -> void:
	player = get_tree().get_nodes_in_group("Player").front()
	# Set collision layer and mask for interaction
	collision_layer = C_Layers.LAYER_COLLECTIBLE
	collision_mask = C_Layers.MASK_COLLECTIBLE | C_Layers.LAYER_WORLD

	# Initialize raycasts
	var raycasts = [raycast_far_left, raycast_mid_left, raycast_near_left, 
					raycast_near_right, raycast_mid_right, raycast_far_right]
	for raycast in raycasts:
		raycast.target_position = Vector2(0, 32)  # Set downward raycast
		raycast.collision_mask = C_Layers.LAYER_WORLD

	# Check initial position and adjust if needed
	call_deferred("_check_and_adjust_position")


func _physics_process(delta: float) -> void:
	# Apply gravity
	velocity.y = min(velocity.y + gravity_force * delta, TERMINAL_VELOCITY)

	# Check for ground collision
	var is_grounded = false
	var raycasts = [raycast_far_left, raycast_mid_left, raycast_near_left, 
					raycast_near_right, raycast_mid_right, raycast_far_right]
	
	for raycast in raycasts:
		raycast.force_raycast_update()
		if raycast.is_colliding():
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
		raycast_data["node"].force_raycast_update()

	# Find the furthest colliding raycast from center
	var furthest_colliding = null
	var max_distance = 0

	for raycast_data in raycasts:
		if raycast_data["node"].is_colliding():
			var distance = abs(raycast_data["offset"])
			if distance > max_distance:
				max_distance = distance
				furthest_colliding = raycast_data

	# Teleport to the furthest colliding raycast's position
	if furthest_colliding:
		position.x += furthest_colliding["offset"]


func store_items(items: Dictionary) -> void:
	stored_items = items.duplicate(true)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not stored_items.is_empty():
		# Restore items to inventory
		for item_id in stored_items.keys():
			Inventory.add_item(item_id, stored_items[item_id])

		# Play recovery sound and effect
		SoundManager.play_sound(Sound.heal, "SFX")

		# Clear stored items
		stored_items.clear()

		# Emit signal that items were recovered
		items_recovered.emit()

		# Queue free the bag
		queue_free()
