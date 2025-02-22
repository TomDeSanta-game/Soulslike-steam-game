extends PanelContainer

@onready var xp_value: Label = %XPValue
@onready var total_xp_label: Label = %TotalXP
@onready var xp_progress: ProgressBar = %XPProgress
@onready var xp_system = get_node("/root/XPSystem")

func _ready() -> void:
	# Wait a frame to ensure nodes are ready
	await get_tree().process_frame
	
	# Set up custom spacing
	var vbox = $MarginContainer/VBoxContainer
	vbox.add_theme_constant_override("separation", 10)  # Increase spacing between elements
	
	# Set up progress bar style
	if xp_progress:
		xp_progress.min_value = 0
		xp_progress.max_value = 1  # We'll use percentage
		xp_progress.value = 0
		# Make progress bar a nice blue color
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.4, 0.8, 1.0)  # Blue color
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		xp_progress.add_theme_stylebox_override("fill", style)
	
	# Connect to XP system signals
	if xp_system:
		xp_system.xp_gained.connect(_on_xp_gained)
		xp_system.level_up.connect(_on_level_up)
	
	# Initial update
	_update_display()

func _update_display() -> void:
	if not xp_system or not xp_value:
		return
	
	var xp_needed = xp_system.get_xp_for_next_level()
	var current_xp = xp_system.current_xp
	var total_xp = xp_system.get_total_xp()
	
	# Update progress bar
	if xp_progress:
		xp_progress.value = float(current_xp) / float(xp_needed)
	
	# Update current XP progress
	xp_value.text = "%s / %s XP" % [
		xp_system.format_xp(current_xp),
		xp_system.format_xp(xp_needed)
	]
	
	# Update total XP
	total_xp_label.text = "Total: %s" % xp_system.format_xp(total_xp)

func _on_xp_gained(_amount: int) -> void:
	_update_display()

func _on_level_up(_new_level: int, _available_points: int) -> void:
	# Flash the progress bar when leveling up
	if xp_progress:
		var tween = create_tween()
		tween.tween_property(xp_progress, "modulate", Color(1.5, 1.5, 1.5), 0.1)
		tween.tween_property(xp_progress, "modulate", Color(1, 1, 1), 0.1)
	_update_display() 
