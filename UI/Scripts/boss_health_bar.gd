extends Control

@onready var health_bar: ProgressBar = $VBoxContainer/HealthBar
@onready var boss_name: Label = $VBoxContainer/BossName

var current_boss: Node = null
var tween: Tween = null

func _ready() -> void:
	# Hide the health bar initially
	modulate.a = 0.0
	hide()
	
	# Connect to boss signals from the correct SignalBus
	SignalBus.boss_spawned.connect(_on_boss_spawned)
	SignalBus.boss_died.connect(_on_boss_died)
	SignalBus.boss_damaged.connect(_on_boss_damaged)

func _on_boss_spawned(boss: Node) -> void:
	if not is_instance_valid(boss):
		return
		
	current_boss = boss
	
	# Update boss name if available
	if "boss_name" in boss:
		boss_name.text = boss.boss_name
	
	# Set initial health
	var max_health = boss.max_health if "max_health" in boss else 100.0
	var current_health = 0.0
	
	if boss.has_method("get_health"):
		current_health = boss.get_health()
	elif boss.has_method("get_vigour"):
		current_health = boss.get_vigour()
	
	health_bar.max_value = max_health
	health_bar.value = current_health
	
	# Show the health bar with a fade in effect
	show()
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

func _on_boss_died(boss: Node) -> void:
	if boss != current_boss:
		return
		
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(hide)
	current_boss = null

func _on_boss_damaged(boss: Node, current_health: float, max_health: float) -> void:
	if not current_boss or not is_instance_valid(current_boss) or boss != current_boss:
		return
		
	# Update max health in case it changed
	health_bar.max_value = max_health
	
	# Smoothly update the health bar
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(health_bar, "value", current_health, 0.2) 