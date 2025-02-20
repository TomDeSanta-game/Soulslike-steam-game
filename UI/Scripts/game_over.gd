extends Control


func _ready() -> void:
	# Ensure this control node can receive focus
	set_focus_mode(Control.FOCUS_ALL)
	# Now grab focus
	grab_focus()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("JUMP"):
		# Change scene to main scene
		SceneManager.change_scene("res://main/main.tscn")

