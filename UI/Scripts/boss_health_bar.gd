extends Control

@onready var health_bar: ProgressBar = $VBoxContainer/HealthBar
@onready var boss_name: Label = $VBoxContainer/BossName

var current_boss: Node = null
var tween: Tween = null

func _ready() -> void:
	# Configure the layout
	custom_minimum_size = Vector2(800, 100)  # Wider bar for more imposing look
	
	# Set anchors and position
	anchors_preset = Control.PRESET_CENTER_TOP
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0
	anchor_bottom = 0
	offset_left = -400  # Half of custom_minimum_size.x
	offset_right = 400
	offset_top = 40  # Move it down a bit
	offset_bottom = 140
	
	# Setup boss name style
	boss_name.add_theme_font_size_override("font_size", 38)  # Larger font
	boss_name.modulate = Color(0.9, 0.8, 0.8, 1.0)  # Slightly bloody tint
	
	# Setup health bar style
	var health_bar_style = StyleBoxFlat.new()
	health_bar_style.bg_color = Color.from_string("#8b0000", Color.DARK_RED)  # Dark blood red
	health_bar_style.corner_radius_top_left = 0  # Sharp corners for more aggressive look
	health_bar_style.corner_radius_top_right = 0
	health_bar_style.corner_radius_bottom_right = 0
	health_bar_style.corner_radius_bottom_left = 0
	health_bar_style.border_width_left = 4
	health_bar_style.border_width_top = 4
	health_bar_style.border_width_right = 4
	health_bar_style.border_width_bottom = 4
	health_bar_style.border_color = Color(0.6, 0.1, 0.1, 0.8)  # Dark blood border
	health_bar_style.shadow_color = Color(0, 0, 0, 0.6)  # Darker shadow
	health_bar_style.shadow_size = 8  # Larger shadow
	health_bar_style.anti_aliasing = true
	
	# Add inner border glow effect
	health_bar_style.expand_margin_left = 6
	health_bar_style.expand_margin_right = 6
	health_bar_style.expand_margin_top = 6
	health_bar_style.expand_margin_bottom = 6

	var health_bar_bg_style = StyleBoxFlat.new()
	health_bar_bg_style.bg_color = Color(0.1, 0.05, 0.05, 0.95)  # Very dark red background
	health_bar_bg_style.corner_radius_top_left = 0
	health_bar_bg_style.corner_radius_top_right = 0
	health_bar_bg_style.corner_radius_bottom_right = 0
	health_bar_bg_style.corner_radius_bottom_left = 0
	health_bar_bg_style.border_width_left = 4
	health_bar_bg_style.border_width_top = 4
	health_bar_bg_style.border_width_right = 4
	health_bar_bg_style.border_width_bottom = 4
	health_bar_bg_style.border_color = Color(0.2, 0.1, 0.1, 0.6)  # Darker border
	health_bar_bg_style.shadow_color = Color(0, 0, 0, 0.7)
	health_bar_bg_style.shadow_size = 10
	health_bar_bg_style.anti_aliasing = true
	
	# Add inner shadow effect
	health_bar_bg_style.expand_margin_left = 6
	health_bar_bg_style.expand_margin_right = 6
	health_bar_bg_style.expand_margin_top = 6
	health_bar_bg_style.expand_margin_bottom = 6
	
	# Apply styles to health bar
	health_bar.add_theme_stylebox_override("fill", health_bar_style)
	health_bar.add_theme_stylebox_override("background", health_bar_bg_style)
	health_bar.custom_minimum_size = Vector2(800, 45)  # Taller bar
	health_bar.modulate.a = 0.98  # Almost solid
	
	# Initially hide the health bar
	modulate.a = 0.0
	show()
	
	# Connect to boss-specific signals
	if not SignalBus.boss_spawned.is_connected(_on_boss_spawned):
		SignalBus.boss_spawned.connect(_on_boss_spawned)
	if not SignalBus.boss_died.is_connected(_on_boss_died):
		SignalBus.boss_died.connect(_on_boss_died)
	if not SignalBus.boss_damaged.is_connected(_on_boss_damaged):
		SignalBus.boss_damaged.connect(_on_boss_damaged)
	if not SignalBus.boss_phase_changed.is_connected(_on_boss_phase_changed):
		SignalBus.boss_phase_changed.connect(_on_boss_phase_changed)

func _process(_delta: float) -> void:
	if not visible or not current_boss or not is_instance_valid(current_boss):
		return
		
	# Keep the health bar centered
	var viewport_size = get_viewport_rect().size
	position.x = (viewport_size.x - custom_minimum_size.x) / 2

func _on_boss_spawned(boss: Node) -> void:
	if not is_instance_valid(boss):
		return
	
	current_boss = boss
	print("Boss spawned with health: ", boss.get_health(), "/", boss.get_max_health())
	
	# Set boss name
	if "boss_name" in boss:
		boss_name.text = boss.boss_name
	
	# Set initial health values
	if boss.has_method("get_health") and boss.has_method("get_max_health"):
		var max_health = boss.get_max_health()
		var current_health = boss.get_health()
		health_bar.max_value = max_health
		health_bar.value = current_health
		print("Set boss health bar to: ", current_health, "/", max_health)
	
	# Show the health bar with fade in
	show()
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

func _on_boss_died(boss: Node) -> void:
	if boss != current_boss:
		return
	
	# Fade out and hide with smooth transition
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): hide(); current_boss = null)

func _on_boss_damaged(boss: Node, current_health: float, max_health: float) -> void:
	if not is_instance_valid(boss) or boss != current_boss:
		return
	
	print("Boss damaged: ", current_health, "/", max_health)
	
	# Update health bar values with smooth tween
	health_bar.max_value = max_health
	
	# Create a smooth tween for health bar updates
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(health_bar, "value", current_health, 0.4)
	
	# Dynamic color change based on health percentage
	var health_style = health_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if health_style:
		var current_health_percent = (current_health / max_health) * 100
		var new_color: Color
		if current_health_percent > 60:
			new_color = Color.from_string("#8b0000", Color.DARK_RED)  # Dark blood red
		elif current_health_percent > 30:
			new_color = Color.from_string("#660000", Color.DARK_RED)  # Darker blood red
		else:
			new_color = Color.from_string("#330000", Color.DARK_RED)  # Almost black red
			
		# Tween the color change
		tween.parallel().tween_method(
			func(c): health_style.bg_color = c,
			health_style.bg_color,
			new_color,
			0.4
		)
	
	# Enhanced damage flash effect
	var flash_tween = create_tween()
	flash_tween.tween_property(health_bar, "modulate", Color(3, 0.5, 0.5, 1), 0.1)  # More red flash
	flash_tween.tween_property(health_bar, "modulate", Color(1, 1, 1, 0.98), 0.3)

func _on_boss_phase_changed(boss: Node, _phase: int) -> void:
	if boss != current_boss:
		return
	
	# More dramatic phase change effect
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	# Multiple flashes for phase change
	tween.tween_property(health_bar, "modulate", Color(3, 0.2, 0.2, 1), 0.1)
	tween.tween_property(health_bar, "modulate", Color(1, 1, 1, 0.98), 0.2)
	tween.tween_property(health_bar, "modulate", Color(2.5, 0.3, 0.3, 1), 0.1)
	tween.tween_property(health_bar, "modulate", Color(1, 1, 1, 0.98), 0.2)

# Override _notification to handle viewport changes
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		# Update position to stay centered when viewport changes
		position.x = (get_viewport_rect().size.x - custom_minimum_size.x) / 2 