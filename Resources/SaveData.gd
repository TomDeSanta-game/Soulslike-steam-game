extends Resource
class_name SaveData

@export var player_position: Vector2
@export var last_bonfire_position: Vector2
@export var current_health: float
@export var current_stamina: float
@export var current_magic: float

func to_dict() -> Dictionary:
	return {
		"player_position": {
			"x": player_position.x,
			"y": player_position.y
		},
		"last_bonfire_position": {
			"x": last_bonfire_position.x,
			"y": last_bonfire_position.y
		},
		"current_health": current_health,
		"current_stamina": current_stamina,
		"current_magic": current_magic
	}

func from_dict(data: Dictionary) -> void:
	player_position = Vector2(
		data.get("player_position", {}).get("x", 0),
		data.get("player_position", {}).get("y", 0)
	)
	last_bonfire_position = Vector2(
		data.get("last_bonfire_position", {}).get("x", 0),
		data.get("last_bonfire_position", {}).get("y", 0)
	)
	current_health = data.get("current_health", 100.0)
	current_stamina = data.get("current_stamina", 100.0)
	current_magic = data.get("current_magic", 100.0)