extends Node2D

@onready var game_ui_scene = preload("res://UI/Scenes/GameUI.tscn")
var game_ui: Node = null
var has_shown_label := false
var boss_health_bar: Control = null

func _ready() -> void:
	# Set up detection area collision
	var detection_area = $DetectionArea
	if detection_area:
		detection_area.collision_layer = 0
		detection_area.collision_mask = 8  # Layer 4 (PLAYER)
		
		# Ensure signal is connected
		if not detection_area.body_entered.is_connected(_on_detection_area_body_entered):
			detection_area.body_entered.connect(_on_detection_area_body_entered)
	
	# Add the UI layer
	game_ui = game_ui_scene.instantiate()
	add_child(game_ui)
	
	# Get reference to boss health bar
	boss_health_bar = game_ui.get_node_or_null("BossHealthBar")
	if boss_health_bar:
		print("Boss health bar found and initialized")
		boss_health_bar.modulate.a = 0.0  # Start fully transparent
		boss_health_bar.show()  # Show but transparent
	else:
		push_error("BossHealthBar node not found in GameUI!")

func _process(delta: float) -> void:
	SoundManager.play_music(Sound.music)
	SoundManager.set_music_volume(0.5)

func _on_detection_area_body_entered(body: Node2D) -> void:
	print("Body entered detection area: ", body.name)
	if body.is_in_group("Player"):
		print("Player detected in boss area")
		if not has_shown_label:
			has_shown_label = true
			LocationLabelManager.show_location_label("The Freezing Den")
		
		# Show the boss health bar when player enters the area
		if boss_health_bar:
			print("Showing boss health bar")
			var tween = create_tween()
			tween.tween_property(boss_health_bar, "modulate:a", 1.0, 0.5)
			
			# Ensure the boss is connected to the health bar
			var boss = get_node_or_null("FrostGuardian")
			if boss:
				print("Found boss, emitting boss_spawned signal")
				SignalBus.boss_spawned.emit(boss)
			else:
				push_error("FrostGuardian node not found in scene!")
		else:
			push_error("Boss health bar not found when player entered!")

func _exit_tree() -> void:
	# Clean up UI when the scene is unloaded
	if game_ui and is_instance_valid(game_ui):
		game_ui.queue_free()
