extends Resource
class_name FrameDataResource

@export var animation_name: String = ""
@export var frames: Array[FrameData] = []


func get_frame(number: int) -> FrameData:
	Log.debug("Looking for frame: " + str(number))
	for frame in frames:
		Log.debug("Checking frame: " + str(frame.frame_number))
		if frame.frame_number == number:
			return frame
	return null
