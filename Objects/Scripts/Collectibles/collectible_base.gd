extends Area2D
class_name CollectibleBase

@export var collect_effect: PackedScene
@export var gives_souls: bool = false  # Flag to control if this collectible gives souls
@export var souls_amount: int = 10  # Amount of souls to give if gives_souls is true

var _is_collected: bool = false
var player = null

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players.front()
	
	# Set collision layers/masks
	collision_layer = C_Layers.LAYER_COLLECTIBLE
	collision_mask = C_Layers.MASK_COLLECTIBLE | C_Layers.LAYER_PLAYER  # Add LAYER_PLAYER to mask
	
	# Connect the area entered signal to handle collection
	area_entered.connect(_on_area_entered)
	
	# Also connect to body_entered for direct player collision
	body_entered.connect(_on_body_entered)

func _on_area_entered(area: Area2D) -> void:
	if _is_collected:
		return

	# Check if this is the player's area or a child of the player
	var area_parent = area.get_parent()
	if area_parent == player or area_parent.is_in_group("Player"):
		collect()

func _on_body_entered(body: Node2D) -> void:
	if _is_collected:
		return
		
	# Check if this is the player directly
	if body == player or body.is_in_group("Player"):
		collect()

func collect() -> void:
	if _is_collected:
		return

	_is_collected = true

	SoundManager.play_sound(Sound.collect, "SFX")

	if collect_effect:
		var effect = collect_effect.instantiate()
		get_tree().current_scene.add_child(effect)
		effect.global_position = global_position

	# Add souls if this collectible is configured to give them
	if gives_souls:
		var souls_system = get_node("/root/SoulsSystem")
		if souls_system:
			souls_system.add_souls(souls_amount)

	SignalBus.collectible_collected.emit(self)
	queue_free()
