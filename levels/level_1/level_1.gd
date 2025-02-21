extends Node2D

@onready var label: Label

@onready var timer: Timer = $Timer

@onready var detection_system: Area2D = $DetectionSystem

var tween: Tween
var has_shown_label := false

func _ready() -> void:
	label = get_tree().get_first_node_in_group("PlaceLabel")

	if label:
		label.visible = false
		label.text = "The Caves"
		label.modulate.a = 0.0

func _process(_delta: float) -> void:
	pass

func _on_detection_system_body_entered(_body: Node2D) -> void:
	if _body.is_in_group("Player") and not has_shown_label:
		has_shown_label = true
		show_location_label()

func show_location_label() -> void:
	if not label:
		return
		
	if tween and tween.is_valid():
		tween.kill()
	
	label.visible = true
	tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Initial fade in
	tween.tween_property(label, "modulate:a", 0.0, 0.0)  # Reset to fully transparent
	tween.tween_property(label, "modulate:a", 1.0, 2.0)  # Slow fade in
	
	# First pulse
	tween.tween_property(label, "modulate:a", 0.6, 0.7)
	tween.tween_property(label, "modulate:a", 1.0, 0.7)
	
	# Second pulse
	tween.tween_property(label, "modulate:a", 0.6, 0.7)
	tween.tween_property(label, "modulate:a", 1.0, 0.7)
	
	# Final fade out
	tween.tween_property(label, "modulate:a", 0.0, 2.0)
	tween.tween_callback(_on_label_animation_finished)

func _on_label_animation_finished() -> void:
	if label:
		label.visible = false
	if timer:
		timer.queue_free()
	if detection_system:
		detection_system.queue_free()

func _on_doom_pit_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		# Call die() on the player
		if body.has_method("_die"):
			body._die()
		# The player's _die() function will handle the transition to game over scene
