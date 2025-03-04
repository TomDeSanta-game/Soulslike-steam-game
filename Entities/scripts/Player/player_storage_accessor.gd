@tool
extends LokStorageAccessor

# Version dictionary to store different versions of the storage accessor
var _versions: Dictionary = {}

# Version 1.0 of the player storage accessor
class Version1_0:
	extends LokStorageAccessorVersion
	
	func _retrieve_data(_dependencies: Dictionary) -> Dictionary:
		var player = Engine.get_main_loop().root.get_first_node_in_group("Player")
		if not player:
			return {}
			
		return {
			"player_position": {
				"x": player.position.x,
				"y": player.position.y
			},
			"current_health": player.current_health,
			"current_stamina": player.stamina,
			"current_magic": player.magic
		}
	
	func _consume_data(data: Dictionary, _dependencies: Dictionary) -> void:
		var player = Engine.get_main_loop().root.get_first_node_in_group("Player")
		if not player:
			return
			
		# Load position
		var pos_data = data.get("player_position", {})
		player.position = Vector2(
			pos_data.get("x", 0),
			pos_data.get("y", 0)
		)
		
		# Load stats
		player.current_health = data.get("current_health", 100.0)
		player.stamina = data.get("current_stamina", 100.0)
		player.magic = data.get("current_magic", 100.0)
		
		# Update UI
		player._update_health_bar()
		player._update_stamina_bar()
		player._update_ui()

func _ready() -> void:
	# Set up the accessor
	id = "player_data"
	partition = "player"
	
	# Add version 1.0
	_versions["1.0"] = Version1_0.new()
	set_version_number("1.0") 