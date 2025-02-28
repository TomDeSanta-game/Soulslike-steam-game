extends Node

# Dictionary to store patrol points for different entities
# Format: { entity_name: [Vector2] }
var patrol_points: Dictionary = {}

# Current patrol index for each entity
# Format: { entity_name: int }
var current_patrol_indices: Dictionary = {}

func register_patrol_points(entity_name: String, points: Array[Vector2]) -> void:
	patrol_points[entity_name] = points
	current_patrol_indices[entity_name] = 0

func get_next_patrol_point(entity_name: String) -> Vector2:
	if not patrol_points.has(entity_name):
		return Vector2.ZERO
	
	var points = patrol_points[entity_name]
	if points.is_empty():
		return Vector2.ZERO
	
	var current_index = current_patrol_indices[entity_name]
	var next_point = points[current_index]
	
	# Update to next index
	current_patrol_indices[entity_name] = (current_index + 1) % points.size()
	
	return next_point

func get_current_patrol_point(entity_name: String) -> Vector2:
	if not patrol_points.has(entity_name):
		return Vector2.ZERO
	
	var points = patrol_points[entity_name]
	if points.is_empty():
		return Vector2.ZERO
	
	return points[current_patrol_indices[entity_name]]

func clear_patrol_points(entity_name: String) -> void:
	patrol_points.erase(entity_name)
	current_patrol_indices.erase(entity_name) 