extends PanelContainer

@onready var xp_value: Label = %XPValue
@onready var xp_system = get_node("/root/XPSystem")

func _ready() -> void:
	# Connect to XP system signals
	xp_system.level_up.connect(_on_level_up)
	xp_system.stat_increased.connect(_on_stat_increased)
	
	# Initial update
	_update_display()

func _update_display() -> void:
	if not xp_system:
		return
	
	var souls_needed = xp_system.get_souls_for_next_level()
	xp_value.text = format_number(souls_needed)

func format_number(number: int) -> String:
	var str_number = str(number)
	var formatted = ""
	var length = str_number.length()
	var comma_count = 0
	
	for i in range(length):
		if i > 0 and (length - i) % 3 == 0:
			formatted = "," + formatted
		formatted = str_number[length - 1 - i] + formatted
	
	return formatted

func _on_level_up(_new_level: int, _available_points: int) -> void:
	_update_display()

func _on_stat_increased(_stat_name: String, _new_value: int) -> void:
	_update_display() 