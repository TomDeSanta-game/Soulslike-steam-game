@tool
extends Resource
class_name PatrolPath

@export var waypoints: Array[Vector2] = []
@export var loop: bool = true  # Whether to loop back to start or reverse direction
@export var wait_times: Array[float] = []  # Wait time at each waypoint
@export var patrol_name: String = "Default Patrol"  # For identifying different patrol routes


func _init() -> void:
	if wait_times.is_empty():
		# Initialize with default wait times
		wait_times.resize(waypoints.size())
		wait_times.fill(1.0)


func add_waypoint(position: Vector2, wait_time: float = 1.0) -> void:
	waypoints.append(position)
	wait_times.append(wait_time)


func remove_waypoint(index: int) -> void:
	if index >= 0 and index < waypoints.size():
		waypoints.remove_at(index)
		wait_times.remove_at(index)


func get_next_waypoint_index(current_index: int) -> int:
	if waypoints.is_empty():
		return -1

	if loop:
		return (current_index + 1) % waypoints.size()
	else:
		# Reverse direction at ends
		if current_index >= waypoints.size() - 1:
			return waypoints.size() - 2
		elif current_index <= 0:
			return 1
		return current_index + 1


func get_wait_time(index: int) -> float:
	if index >= 0 and index < wait_times.size():
		return wait_times[index]
	return 1.0  # Default wait time


func clear() -> void:
	waypoints.clear()
	wait_times.clear()
