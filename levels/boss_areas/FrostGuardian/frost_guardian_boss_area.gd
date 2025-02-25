extends Node2D

var has_shown_label := false

func _ready() -> void:
	# Set up detection area collision
	var detection_area = $DetectionArea
	if detection_area:
		detection_area.collision_layer = 0
		detection_area.collision_mask = 8  # Layer 4 (PLAYER)

func _on_detection_area_body_entered(body:Node2D) -> void:
	if body.is_in_group("Player") and not has_shown_label:
		has_shown_label = true
		LocationLabelManager.show_location_label("The Freezing Den")
