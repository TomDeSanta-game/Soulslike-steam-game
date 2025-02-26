extends Control

@onready var health_bar: ProgressBar = $VBoxContainer/HealthBar
@onready var boss_name: Label = $VBoxContainer/BossName

var current_boss: Node = null
var tween: Tween = null

func _ready() -> void:
	# Configure the layout
	custom_minimum_size = Vector2(600, 80)
	
	# Set anchors and position
	anchors_preset = Control.PRESET_CENTER_TOP
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0
	anchor_bottom = 0
	offset_left = -300  # Half of custom_minimum_size.x
	offset_right = 300
	offset_top = 20
	offset_bottom = 100  # offset_top + custom_minimum_size.y
	
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
	
	# Show the health bar
	show()
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

func _on_boss_died(boss: Node) -> void:
	if boss != current_boss:
		return
	
	# Fade out and hide
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): hide(); current_boss = null)

func _on_boss_damaged(boss: Node, current_health: float, max_health: float) -> void:
	if not is_instance_valid(boss) or boss != current_boss:
		return
	
	print("Boss damaged: ", current_health, "/", max_health)
	
	# Update health bar values
	health_bar.max_value = max_health
	
	# Animate health change
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(health_bar, "value", current_health, 0.2)

func _on_boss_phase_changed(boss: Node, _phase: int) -> void:
	if boss != current_boss:
		return
	
	# Flash the health bar on phase change
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.5, 0.1)
	tween.tween_property(self, "modulate:a", 1.0, 0.1)

# Override _notification to handle viewport changes
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		# Update position to stay centered when viewport changes
		position.x = (get_viewport_rect().size.x - custom_minimum_size.x) / 2 