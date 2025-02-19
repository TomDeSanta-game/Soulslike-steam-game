extends Control


func _ready() -> void:
	# Ensure this control node has focus to receive input
	grab_focus()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("JUMP"):
		# Change scene to main scene
		SceneManager.change_scene("res://main/main.tscn")

