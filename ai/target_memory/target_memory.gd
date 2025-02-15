extends Node

class_name TargetMemory

# Constants for memory configuration
const DEFAULT_MEMORY_DURATION: float = 5.0  # How long to remember a target after losing sight
const DEFAULT_CONFIDENCE_DECAY: float = 0.2  # How quickly confidence decays per second
const MIN_CONFIDENCE: float = 0.1  # Minimum confidence before forgetting target
const MAX_CONFIDENCE: float = 1.0  # Maximum confidence when directly seeing target

# Target information structure
class TargetInfo:
	var target: Node  # The actual target node
	var last_known_position: Vector2  # Last known position of target
	var last_seen_time: float  # Time when target was last seen
	var confidence: float  # Confidence level in target's position (0.0 to 1.0)
	var velocity: Vector2  # Last known velocity of target
	
	func _init(target_node: Node, pos: Vector2, time: float) -> void:
		target = target_node
		last_known_position = pos
		last_seen_time = time
		confidence = MAX_CONFIDENCE
		velocity = Vector2.ZERO if not target is CharacterBody2D else (target as CharacterBody2D).velocity

# Memory properties
var memory_duration: float = DEFAULT_MEMORY_DURATION
var confidence_decay: float = DEFAULT_CONFIDENCE_DECAY
var targets: Dictionary = {}  # Dictionary of target_id: TargetInfo

# Owner reference (the enemy using this memory system)
var memory_owner: Node

func _init(owner_node: Node) -> void:
	memory_owner = owner_node


func update_target(target: Node, can_see: bool = true) -> void:
	var target_id = target.get_instance_id()
	
	if can_see:
		if not targets.has(target_id):
			# New target spotted
			targets[target_id] = TargetInfo.new(target, target.global_position, Time.get_unix_time_from_system())
		else:
			# Update existing target
			var info = targets[target_id]
			info.last_known_position = target.global_position
			info.last_seen_time = Time.get_unix_time_from_system()
			info.confidence = MAX_CONFIDENCE
			if target is CharacterBody2D:
				info.velocity = (target as CharacterBody2D).velocity


func process_memory(delta: float) -> void:
	var current_time = Time.get_unix_time_from_system()
	var targets_to_remove = []
	
	for target_id in targets:
		var info = targets[target_id]
		var time_since_last_seen = current_time - info.last_seen_time
		
		# Update confidence based on time
		info.confidence = max(MIN_CONFIDENCE, 
			info.confidence - confidence_decay * delta)
		
		# Estimate current position based on last known velocity
		info.last_known_position += info.velocity * delta
		
		# Check if we should forget this target
		if time_since_last_seen > memory_duration or info.confidence <= MIN_CONFIDENCE:
			targets_to_remove.append(target_id)
	
	# Remove forgotten targets
	for target_id in targets_to_remove:
		targets.erase(target_id)


func get_most_confident_target() -> Dictionary:
	var highest_confidence = MIN_CONFIDENCE
	var best_target_info = null
	
	for info in targets.values():
		if info.confidence > highest_confidence:
			highest_confidence = info.confidence
			best_target_info = info
	
	if best_target_info:
		return {
			"target": best_target_info.target,
			"position": best_target_info.last_known_position,
			"confidence": best_target_info.confidence,
			"velocity": best_target_info.velocity
		}
	
	return {}


func get_target_info(target: Node) -> Dictionary:
	var target_id = target.get_instance_id()
	if targets.has(target_id):
		var info = targets[target_id]
		return {
			"target": info.target,
			"position": info.last_known_position,
			"confidence": info.confidence,
			"velocity": info.velocity
		}
	return {}


func has_target(target: Node) -> bool:
	return targets.has(target.get_instance_id())


func forget_target(target: Node) -> void:
	var target_id = target.get_instance_id()
	if targets.has(target_id):
		targets.erase(target_id)


func forget_all_targets() -> void:
	targets.clear()


func get_all_targets() -> Array:
	var target_list = []
	for info in targets.values():
		target_list.append({
			"target": info.target,
			"position": info.last_known_position,
			"confidence": info.confidence,
			"velocity": info.velocity
		})
	return target_list


func predict_target_position(target: Node, time_ahead: float) -> Vector2:
	var target_id = target.get_instance_id()
	if not targets.has(target_id):
		return Vector2.ZERO
		
	var info = targets[target_id]
	return info.last_known_position + (info.velocity * time_ahead) 