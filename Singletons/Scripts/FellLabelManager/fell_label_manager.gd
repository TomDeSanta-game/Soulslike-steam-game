extends Node

@warning_ignore("unused_signal")
signal enemy_felled(enemy_name: String)

var label = null
var tween: Tween
var background: ColorRect
var top_line: ColorRect
var bottom_line: ColorRect
var container: CenterContainer
var particles_left: CPUParticles2D
var particles_right: CPUParticles2D
var glow_rect: ColorRect
var shockwave: ColorRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 128
	add_child(canvas_layer)
	_setup_label()

func _setup_label() -> void:
	label = Label.new()
	label.text = "GREAT ENEMY FELLED"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.custom_minimum_size = Vector2(1920, 300)
	
	var custom_font = SystemFont.new()
	custom_font.font_names = ["OptimusPrincepsSemiBold", "Times New Roman"]
	label.add_theme_font_override("font", custom_font)
	label.add_theme_font_size_override("font_size", 96)
	label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.5))
	label.modulate.a = 0
	label.scale = Vector2(0.5, 0.5)
	label.pivot_offset = Vector2(960, 150)
	
	var canvas_layer = get_node_or_null("CanvasLayer")
	if not canvas_layer:
		canvas_layer = CanvasLayer.new()
		canvas_layer.name = "CanvasLayer"
		add_child(canvas_layer)
	
	container = CenterContainer.new()
	container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	container.offset_top = 0
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.size = Vector2(get_viewport().get_visible_rect().size.x, 300)
	canvas_layer.add_child(container)
	
	background = ColorRect.new()
	background.custom_minimum_size = Vector2(1920, 300)
	background.size = Vector2(1920, 300)
	background.color = Color(0.0, 0.0, 0.0, 1.0)
	background.modulate.a = 0
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(background)
	
	shockwave = ColorRect.new()
	shockwave.custom_minimum_size = Vector2(1920, 300)
	shockwave.size = Vector2(1920, 300)
	shockwave.color = Color(0.9, 0.85, 0.5, 0.2)
	shockwave.modulate.a = 0
	shockwave.scale = Vector2(0.5, 0.5)
	shockwave.pivot_offset = Vector2(960, 150)
	background.add_child(shockwave)
	
	glow_rect = ColorRect.new()
	glow_rect.custom_minimum_size = Vector2(1200, 150)
	glow_rect.size = Vector2(1200, 150)
	glow_rect.position = Vector2(360, 75)
	glow_rect.color = Color(0.9, 0.85, 0.5, 0.15)
	glow_rect.modulate.a = 0
	background.add_child(glow_rect)
	
	particles_left = CPUParticles2D.new()
	particles_right = CPUParticles2D.new()
	
	for particles in [particles_left, particles_right]:
		particles.emitting = false
		particles.amount = 50
		particles.lifetime = 2.0
		particles.explosiveness = 0.1
		particles.randomness = 1.0
		particles.direction = Vector2(0, -1)
		particles.gravity = Vector2(0, 200)
		particles.initial_velocity_min = 100
		particles.initial_velocity_max = 200
		particles.scale_amount_min = 2
		particles.scale_amount_max = 4
		particles.color = Color(0.9, 0.85, 0.5, 1.0)
		background.add_child(particles)
	
	particles_left.position = Vector2(600, 150)
	particles_right.position = Vector2(1320, 150)
	
	background.add_child(label)
	
	# Add sparkle particles
	var sparkles_left = CPUParticles2D.new()
	var sparkles_right = CPUParticles2D.new()
	
	# Configure sparkle particles
	for sparkles in [sparkles_left, sparkles_right]:
		sparkles.emitting = false
		sparkles.amount = 30
		sparkles.lifetime = 1.5
		sparkles.explosiveness = 0.6
		sparkles.randomness = 0.8
		sparkles.direction = Vector2(0, -1)
		sparkles.gravity = Vector2(0, 50)  # Less gravity for floating effect
		sparkles.initial_velocity_min = 100
		sparkles.initial_velocity_max = 200
		sparkles.scale_amount_min = 1
		sparkles.scale_amount_max = 2
		sparkles.color = Color(1.0, 0.95, 0.7, 1.0)  # Brighter golden color
		background.add_child(sparkles)
	
	sparkles_left.position = Vector2(700, 150)
	sparkles_right.position = Vector2(1220, 150)
	
	# Create top line
	top_line = ColorRect.new()
	top_line.custom_minimum_size = Vector2(1920, 4)
	top_line.color = Color(0.6, 0.6, 0.6, 1.0)
	top_line.position.y = -4
	top_line.modulate.a = 0
	top_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(top_line)
	
	# Create bottom line
	bottom_line = ColorRect.new()
	bottom_line.custom_minimum_size = Vector2(1920, 4)
	bottom_line.color = Color(0.6, 0.6, 0.6, 1.0)
	bottom_line.position.y = 300
	bottom_line.modulate.a = 0
	bottom_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(bottom_line)
	
	# Initially hide the container
	container.hide()
	
	print("FellLabelManager: Label setup complete.")

# Add the glow pulse function as a class method
func _create_glow_pulse() -> void:
	if is_instance_valid(glow_rect) and glow_rect.visible:
		var new_tween = create_tween()
		new_tween.tween_property(glow_rect, "scale", Vector2(1.1, 1.1), 0.5)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN)
		new_tween.tween_property(glow_rect, "scale", Vector2(1.0, 1.0), 0.5)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)
		new_tween.tween_interval(0.1)
		new_tween.chain().tween_callback(_create_glow_pulse)

func show_fell_message() -> void:
	print("FellLabelManager: Starting show_fell_message...")
	
	if not label or not is_instance_valid(label):
		print("FellLabelManager: Label not valid, setting up...")
		_setup_label()
		if not label or not is_instance_valid(label):
			print("FellLabelManager: Failed to setup label!")
			return
	
	print("FellLabelManager: Making container visible...")
	container.show()
	if container.get_parent() is CanvasLayer:
		container.get_parent().layer = 128
	
	container.size.x = get_viewport().get_visible_rect().size.x
	
	if tween and tween.is_valid():
		tween.kill()
	
	# Reset initial states
	background.modulate.a = 0.0
	label.modulate.a = 0.0
	top_line.modulate.a = 0.0
	bottom_line.modulate.a = 0.0
	glow_rect.modulate.a = 0.0
	shockwave.modulate.a = 0.0
	label.scale = Vector2(0.5, 0.5)
	shockwave.scale = Vector2(0.5, 0.5)
	
	# Create dramatic entrance tween
	tween = create_tween().set_parallel()
	
	# Background fade in
	tween.tween_property(background, "modulate:a", 1.0, 0.3)
	
	# Shockwave effect
	tween.tween_property(shockwave, "scale", Vector2(1.2, 1.2), 0.5)\
		.set_trans(Tween.TRANS_EXPO)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(shockwave, "modulate:a", 0.4, 0.2)\
		.from(0.0)
	tween.tween_property(shockwave, "modulate:a", 0.0, 0.3)\
		.set_delay(0.2)
	
	# Text zoom and fade with glow
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.5)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 1.0, 0.3)
	
	# Glow effect
	tween.tween_property(glow_rect, "modulate:a", 0.8, 0.3)
	
	# Create a separate tween for the continuous glow pulsing
	var glow_tween = create_tween()
	glow_tween.tween_property(glow_rect, "scale", Vector2(1.1, 1.1), 0.5)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)
	glow_tween.tween_property(glow_rect, "scale", Vector2(1.0, 1.0), 0.5)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	glow_tween.tween_interval(0.1)
	glow_tween.chain().tween_callback(_create_glow_pulse)
	
	# Lines slide in
	tween.tween_property(top_line, "modulate:a", 1.0, 0.3)
	tween.tween_property(bottom_line, "modulate:a", 1.0, 0.3)
	
	# Start all particle effects
	for particle in background.get_children():
		if particle is CPUParticles2D:
			particle.emitting = true
	
	# Hold for display duration
	await get_tree().create_timer(2.0).timeout
	
	# Create exit tween
	tween = create_tween().set_parallel()
	
	# Fade out everything
	tween.tween_property(background, "modulate:a", 0.0, 0.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_property(top_line, "modulate:a", 0.0, 0.5)
	tween.tween_property(bottom_line, "modulate:a", 0.0, 0.5)
	tween.tween_property(glow_rect, "modulate:a", 0.0, 0.5)
	
	# Scale up slightly while fading
	tween.tween_property(label, "scale", Vector2(1.1, 1.1), 0.5)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)
	
	# Final shockwave effect
	tween.tween_property(shockwave, "scale", Vector2(1.4, 1.4), 0.5)\
		.set_trans(Tween.TRANS_EXPO)\
		.set_ease(Tween.EASE_IN)
	tween.tween_property(shockwave, "modulate:a", 0.3, 0.2)\
		.from(0.0)
	tween.tween_property(shockwave, "modulate:a", 0.0, 0.3)
	
	# Stop particles
	for particle in background.get_children():
		if particle is CPUParticles2D:
			particle.emitting = false
	
	await tween.finished
	container.hide()


	
