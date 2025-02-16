extends Node

const SAVE_FILE_PATH = "user://save_data.json"
const SAVE_RESOURCE_PATH = "user://save_data.tres"

var current_save_data: SaveData

func _ready() -> void:
	current_save_data = SaveData.new()


func save_game() -> void:
	# Save as Resource
	var err = ResourceSaver.save(current_save_data, SAVE_RESOURCE_PATH)
	if err != OK:
		push_error("Failed to save game data as resource")
	
	# Save as JSON
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(current_save_data.to_dict())
		file.store_string(json_string)
	else:
		push_error("Failed to save game data as JSON")


func load_game() -> bool:
	# Try loading from Resource first
	if ResourceLoader.exists(SAVE_RESOURCE_PATH):
		var loaded_resource = ResourceLoader.load(SAVE_RESOURCE_PATH)
		if loaded_resource is SaveData:
			current_save_data = loaded_resource
			return true
	
	# If resource load fails, try JSON
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if parse_result == OK:
				var data = json.get_data()
				current_save_data.from_dict(data)
				return true
	
	return false


func update_save_data(player_node: Node2D) -> void:
	current_save_data.player_position = player_node.position
	current_save_data.current_health = player_node.current_health
	current_save_data.current_stamina = player_node.stamina
	current_save_data.current_magic = player_node.magic


func set_last_bonfire(position: Vector2) -> void:
	current_save_data.last_bonfire_position = position
	save_game()


func get_last_bonfire_position() -> Vector2:
	return current_save_data.last_bonfire_position


func get_save_data() -> SaveData:
	return current_save_data