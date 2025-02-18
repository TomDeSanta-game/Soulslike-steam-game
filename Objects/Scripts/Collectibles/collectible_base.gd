extends Area2D
class_name CollectibleBase

@export var collect_effect: PackedScene

var _is_collected: bool = false
var player = null

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players.front()
	
	# Set collision layers/masks
	collision_layer = C_Layers.LAYER_COLLECTIBLE
	collision_mask = C_Layers.MASK_COLLECTIBLE
	
	# Connect the area entered signal to handle collection
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if _is_collected:
		return

	if area.get_parent() == player:
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

	SignalBus.collectible_collected.emit(self)
	queue_free()
