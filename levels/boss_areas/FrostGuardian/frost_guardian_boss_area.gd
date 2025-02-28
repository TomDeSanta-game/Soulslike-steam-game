extends Node2D

@onready var game_ui_scene = preload("res://UI/Scenes/GameUI.tscn")
@onready var frost_power_shader = preload("res://Shaders/Bosses/frost_power_shader.gdshader")
var game_ui: Node = null
var has_shown_label := false
var boss_health_bar: Control = null
var camera_flipped := false

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
	
	# Connect to boss signals
	SignalBus.boss_damaged.connect(_on_boss_damaged)
	SignalBus.boss_died.connect(_on_boss_died)

func _process(_delta: float) -> void:
	SoundManager.play_music(Sound.music, 1.0, "Music")
	SoundManager.set_music_volume(0.5)

func _on_boss_damaged(boss: Node, current_health: float, max_health: float) -> void:
	if boss.name == "FrostGuardian":
		print("Boss damaged: Health = ", current_health, "/", max_health)
		var health_percent = (current_health / max_health) * 100
		print("Health percentage: ", health_percent, "%")
		if health_percent <= 50 and not camera_flipped:
			print("Triggering camera flip!")
			_trigger_camera_flip()
			_enhance_boss_phase_two(boss)

func _on_boss_died(boss: Node) -> void:
	if boss.name == "FrostGuardian":
		print("Boss died, resetting camera...")
		_reset_camera()
		# The fell message is now handled in the boss's die() function

func _reset_camera() -> void:
	var camera = get_viewport().get_camera_2d()
	if not camera:
		var player = get_tree().get_first_node_in_group("Player")
		if player:
			camera = player.get_node_or_null("Camera2D")
	
	if camera:
		print("Found camera, resetting rotation...")
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(camera, "rotation_degrees", 0, 1.0)
		if camera_flipped:
			tween.parallel().tween_property(camera, "zoom", Vector2(abs(camera.zoom.x), abs(camera.zoom.y)), 1.0)
		camera_flipped = false

func _enhance_boss_phase_two(boss: Node) -> void:
	if not boss or not boss.has_method("set_attack_damage"):
		return
		
	# Increase attack damage by 50%
	boss.attack_damage *= 1.5
	
	# Increase speed by 40%
	if "chase_speed" in boss:
		boss.chase_speed *= 1.4
	if "patrol_speed" in boss:
		boss.patrol_speed *= 1.4
	
	# Apply power shader to boss sprite
	var sprite = boss.get_node_or_null("AnimatedSprite2D")
	if sprite:
		var frost_power_material = ShaderMaterial.new()
		frost_power_material.shader = frost_power_shader
		sprite.material = frost_power_material

func _trigger_camera_flip() -> void:
	camera_flipped = true
	
	# Try different ways to find the camera
	var camera = get_viewport().get_camera_2d()
	if not camera:
		var player = get_tree().get_first_node_in_group("Player")
		if player:
			camera = player.get_node_or_null("Camera2D")
	
	if camera:
		print("Found camera, flipping...")
		# Create a smooth rotation effect for the camera
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(camera, "rotation_degrees", 180, 1.0)
		# Flip the camera's zoom to maintain correct orientation
		tween.parallel().tween_property(camera, "zoom", Vector2(-camera.zoom.x, -camera.zoom.y), 1.0)
	else:
		print("Camera not found in any location!")

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
	
	# Disconnect from signals
	if SignalBus.boss_damaged.is_connected(_on_boss_damaged):
		SignalBus.boss_damaged.disconnect(_on_boss_damaged)
	if SignalBus.boss_died.is_connected(_on_boss_died):
		SignalBus.boss_died.disconnect(_on_boss_died)
