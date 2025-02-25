extends Node

# Dictionary to store active bags and their data
# Key: unique ID, Value: Dictionary with bag data (position, items)
var active_bags: Dictionary = {}
var bag_scene: PackedScene = preload("res://Objects/Scenes/Bag/bag.tscn")

# Signal for when a bag is recovered
@warning_ignore("unused_signal")
signal bag_recovered(bag_id: String)

# List of scene paths where bags should not be spawned
const EXCLUDED_SCENES = [
	"res://UI/Scenes/game_over.tscn",
	# Add any other non-gameplay scenes here
]

func _ready() -> void:
	# Connect to SceneManager's scene_loaded signal
	SceneManager.scene_loaded.connect(_on_scene_loaded)
	
	# Connect to the SignalBus souls_recovered signal
	SignalBus.souls_recovered.connect(_on_souls_recovered)

func spawn_bag(position: Vector2, items: Dictionary) -> void:
	# Don't spawn bags in excluded scenes
	if _is_excluded_scene():
		return
		
	# Generate a unique ID for the bag
	var bag_id = str(Time.get_unix_time_from_system()) + str(randi())
	
	# Store the bag data
	active_bags[bag_id] = {
		"position": position,
		"items": items.duplicate(true),
		"instance_id": 0  # Will store the instance ID of the bag
	}
	
	# Create and setup the bag instance
	var bag = bag_scene.instantiate()
	bag.position = position
	bag.store_items(items)
	
	# Store the bag's instance ID to identify it later
	active_bags[bag_id]["instance_id"] = bag.get_instance_id()
	
	# Add the bag to the current scene
	get_tree().current_scene.add_child(bag)

# Called when souls_recovered signal is emitted
func _on_souls_recovered(_amount_recovered: int) -> void:
	# Find which bag was recovered based on instance ID
	var bag_id_to_remove = ""
	
	for bag_id in active_bags.keys():
		var bag_instance_id = active_bags[bag_id]["instance_id"]
		
		# Check if this bag instance still exists in the scene
		if not is_instance_valid(instance_from_id(bag_instance_id)):
			bag_id_to_remove = bag_id
			break
	
	# If we found a bag that was recovered
	if bag_id_to_remove != "":
		_on_bag_recovered(bag_id_to_remove)

func _on_bag_recovered(bag_id: String) -> void:
	# Remove the bag data from active_bags when it's recovered
	if active_bags.has(bag_id):
		active_bags.erase(bag_id)
	emit_signal("bag_recovered", bag_id)

func respawn_active_bags() -> void:
	# Don't spawn bags in excluded scenes
	if _is_excluded_scene():
		return
		
	# Called when changing scenes to respawn any active bags
	for bag_id in active_bags.keys():
		var bag_data = active_bags[bag_id]
		var bag = bag_scene.instantiate()
		bag.position = bag_data["position"]
		bag.store_items(bag_data["items"])
		
		# Update the instance ID for the new bag instance
		active_bags[bag_id]["instance_id"] = bag.get_instance_id()
		
		# Add the bag to the scene
		get_tree().current_scene.add_child(bag)

# Call this when a scene is loaded
func _on_scene_loaded() -> void:
	respawn_active_bags()

# Helper function to check if current scene is in excluded list
func _is_excluded_scene() -> bool:
	var current_scene_path = get_tree().current_scene.scene_file_path
	return current_scene_path in EXCLUDED_SCENES 
