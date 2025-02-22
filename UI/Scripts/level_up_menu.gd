extends PanelContainer

# Node references
@onready var level_label: Label = %LevelValue
@onready var souls_needed_label: Label = %SoulsNeededValue
@onready var points_label: Label = %PointsValue
@onready var level_up_button: Button = %LevelUpButton

# Stat value labels
@onready var vigour_label: Label = %VigourValue
@onready var endurance_label: Label = %EnduranceValue
@onready var strength_label: Label = %StrengthValue
@onready var dexterity_label: Label = %DexterityValue
@onready var intelligence_label: Label = %IntelligenceValue
@onready var faith_label: Label = %FaithValue

# Stat increase buttons
@onready var vigour_inc: Button = %VigourInc
@onready var endurance_inc: Button = %EnduranceInc
@onready var strength_inc: Button = %StrengthInc
@onready var dexterity_inc: Button = %DexterityInc
@onready var intelligence_inc: Button = %IntelligenceInc
@onready var faith_inc: Button = %FaithInc

# Systems
@onready var xp_system = get_node("/root/XPSystem")
@onready var souls_system = get_node("/root/SoulsSystem")


func _ready() -> void:
	# Connect button signals
	level_up_button.pressed.connect(_on_level_up_pressed)
	$MarginContainer/VBoxContainer/Buttons/CloseButton.pressed.connect(_on_close_pressed)

	# Connect stat increase buttons
	vigour_inc.pressed.connect(func(): _increase_stat("vigour"))
	endurance_inc.pressed.connect(func(): _increase_stat("endurance"))
	strength_inc.pressed.connect(func(): _increase_stat("strength"))
	dexterity_inc.pressed.connect(func(): _increase_stat("dexterity"))
	intelligence_inc.pressed.connect(func(): _increase_stat("intelligence"))
	faith_inc.pressed.connect(func(): _increase_stat("faith"))

	# Connect XP system signals
	xp_system.xp_gained.connect(_on_xp_gained)
	xp_system.level_up.connect(_on_level_up)

	# Initial update
	update_display()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		_on_close_pressed()


func show_menu() -> void:
	update_display()
	show()
	get_tree().paused = true


func hide_menu() -> void:
	hide()
	get_tree().paused = false


func update_display() -> void:
	if not xp_system:
		return

	# Update level info
	level_label.text = str(xp_system.current_level)
	
	var xp_needed = xp_system.get_xp_for_next_level()
	var current_xp = xp_system.current_xp
	souls_needed_label.text = "%s / %s XP" % [xp_system.format_xp(current_xp), xp_system.format_xp(xp_needed)]
	points_label.text = str(xp_system.available_points)
	
	# Update stats
	var stats = xp_system.get_stats()
	vigour_label.text = str(stats.vigour)
	endurance_label.text = str(stats.endurance)
	strength_label.text = str(stats.strength)
	dexterity_label.text = str(stats.dexterity)
	intelligence_label.text = str(stats.intelligence)
	faith_label.text = str(stats.faith)

	# Update button states
	var has_points = xp_system.available_points > 0
	vigour_inc.disabled = not has_points
	endurance_inc.disabled = not has_points
	strength_inc.disabled = not has_points
	dexterity_inc.disabled = not has_points
	intelligence_inc.disabled = not has_points
	faith_inc.disabled = not has_points

	# Update level up button
	level_up_button.disabled = current_xp < xp_needed


func _increase_stat(stat_name: String) -> void:
	if xp_system.increase_stat(stat_name):
		update_display()


func _on_xp_gained(_amount: int) -> void:
	update_display()


func _on_level_up(_new_level: int, _points: int) -> void:
	update_display()
	# Play level up sound/effect
	SoundManager.play_sound(Sound.collect, "SFX")  # Temporarily use collect sound until proper level up sound is added


func _on_level_up_pressed() -> void:
	if xp_system:
		xp_system.add_xp(0)  # This will trigger level up if we have enough XP


func _on_close_pressed() -> void:
	hide_menu()
