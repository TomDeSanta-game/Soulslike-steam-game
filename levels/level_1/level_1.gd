extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var label: Label = $Label

@onready var timer: Timer = $Timer


func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	pass


func _on_detection_system_body_entered(_body: Node2D) -> void:
	timer.start()


func _on_timer_timeout() -> void:
	label.self_modulate = 80
	label.show()
	# Connect the signal just before playing the animation
	if not animation_player.animation_finished.is_connected(_on_text_show_finished):
		animation_player.animation_finished.connect(_on_text_show_finished)
	animation_player.play("TextShow")


func _on_text_show_finished(anim_name: String) -> void:
	if anim_name == "TextShow":
		# Disconnect the signal to prevent multiple calls
		if animation_player.animation_finished.is_connected(_on_text_show_finished):
			animation_player.animation_finished.disconnect(_on_text_show_finished)
		# Queue free the nodes after the TextShow animation
		timer.queue_free()
		label.queue_free()
		animation_player.queue_free()


func _on_doom_pit_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		# Call die() on the player
		if body.has_method("_die"):
			body._die()
		# The player's _die() function will handle the transition to game over scene
