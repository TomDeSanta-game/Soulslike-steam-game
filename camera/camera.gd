extends Camera2D

# Screenshake variables
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_decay: float = 0.0


func _process(delta: float) -> void:
	if shake_duration > 0:
		# Randomize the camera's offset
		offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)

		# Reduce the shake intensity over time
		shake_intensity *= shake_decay
		shake_duration -= delta
	else:
		# Reset the camera offset when the shake is done
		offset = Vector2.ZERO


# Call this function to start the screenshake
func shake(new_intensity: float, new_duration: float, new_decay: float = 0.9) -> void:
	shake_intensity = new_intensity
	shake_duration = new_duration
	shake_decay = new_decay
