extends Node2D

@onready var timer: Timer = $Timer
@onready var detection_system: Area2D = $DetectionSystem


var has_shown_label := false

func _ready() -> void:
	# Set up detection system collision
	if detection_system:
		detection_system.collision_layer = C_Layers.LAYER_WORLD
		detection_system.collision_mask = C_Layers.LAYER_PLAYER

func _on_detection_system_body_entered(_body: Node2D) -> void:
	if _body.is_in_group("Player") and not has_shown_label:
		has_shown_label = true
		LocationLabelManager.show_location_label("The Caves")

func _on_doom_pit_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		# Call die() on the player
		if body.has_method("_die"):
			body._die()
		# The player's _die() function will handle the transition to game over scene
