extends Resource
class_name InventoryItem

@export var id: String = ""
@export var name: String = ""
@export var texture: Texture2D
@export var quantity: int = 0
@export_multiline var description: String = ""

func _init(p_id: String = "", p_name: String = "", p_texture: Texture2D = null, p_description: String = "") -> void:
	id = p_id
	name = p_name
	texture = p_texture
	description = p_description
	quantity = 1 