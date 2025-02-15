extends Resource
class_name FrameDataResource

@export var animation_name: String = ""
@export var frames: Array[FrameData] = []


func get_frame(number: int) -> FrameData:
	print("Looking for frame: ", number)  # Debug print
	for frame in frames:
		print("Checking frame: ", frame.frame_number)  # Debug print
		if frame.frame_number == number:
			return frame
	return null
