extends Node2D


func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	pass


func _on_detection_system_body_entered(_body: Node2D) -> void:
	$Timer.start()


func _on_timer_timeout() -> void:
	%Label.self_modulate = 80
	%Label.show()
	%AnimationPlayer.play("TextShow")


func _on_doom_pit_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		# Call die() on the player
		if body.has_method("_die"):
			body._die()
		# Queue the body for deletion after physics frame
		body.call_deferred("queue_free")
		# Wait a bit then reload the current scene
		await get_tree().create_timer(2.0).timeout
		# Get the current scene path and reload it
		var current_scene = get_tree().current_scene.scene_file_path

		SceneManager.change_scene(current_scene)
