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
	xp_system.level_up.connect(_on_level_up)
	xp_system.stat_increased.connect(_on_stat_increased)

	# Initial update
	_update_display()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		_on_close_pressed()


func show_menu() -> void:
	_update_display()
	show()
	get_tree().paused = true


func hide_menu() -> void:
	hide()
	get_tree().paused = false


func _update_display() -> void:
	if not xp_system or not souls_system:
		return

	# Update level info
	level_label.text = str(xp_system.current_level)
	souls_needed_label.text = str(xp_system.get_souls_for_next_level())
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
	level_up_button.disabled = souls_system.get_souls() < xp_system.get_souls_for_next_level()


func _increase_stat(stat_name: String) -> void:
	if xp_system.increase_stat(stat_name):
		_update_display()


func _on_level_up(new_level: int, available_points: int) -> void:
	_update_display()
	# Play level up sound/effect
	SoundManager.play_sound(Sound.heal, "SFX")  # Replace with proper level up sound


func _on_stat_increased(stat_name: String, new_value: int) -> void:
	_update_display()
	# Play stat increase sound/effect
	SoundManager.play_sound(Sound.collect, "SFX")  # Replace with proper stat increase sound


func _on_level_up_pressed() -> void:
	xp_system.try_level_up()


func _on_close_pressed() -> void:
	hide_menu()
