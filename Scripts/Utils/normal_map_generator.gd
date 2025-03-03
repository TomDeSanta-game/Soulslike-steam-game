extends Node

class_name NormalMapGenerator

static func generate_normal_map(texture: Texture2D, _strength: float = 2.0) -> ImageTexture:
	var image = texture.get_image()
	var width = image.get_width()
	var height = image.get_height()
	
	# Create a new image for the normal map
	var normal_map = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	# Fill with default normal (facing forward)
	for x in range(width):
		for y in range(height):
			var color = image.get_pixel(x, y)
			# If pixel is transparent, make normal map transparent too
			if color.a < 0.5:
				normal_map.set_pixel(x, y, Color(0.5, 0.5, 1.0, 0.0))
			else:
				# Pure reflection normal map (0.5, 0.5, 1.0)
				# Using full alpha for clean reflections
				normal_map.set_pixel(x, y, Color(0.5, 0.5, 1.0, 1.0))
	
	return ImageTexture.create_from_image(normal_map)

static func apply_normal_maps_to_animated_sprite(sprite: AnimatedSprite2D, strength: float = 2.0) -> void:
	# Basic visibility setup
	sprite.visible = true
	sprite.modulate = Color(1, 1, 1, 1)
	sprite.self_modulate = Color(1, 1, 1, 1)
	sprite.use_parent_material = false
	
	# Light receiving setup for clean reflections
	sprite.light_mask = 1  # Receive light
	
	# Create a canvas material optimized for reflections
	var canvas_material = CanvasItemMaterial.new()
	canvas_material.light_mode = CanvasItemMaterial.LIGHT_MODE_NORMAL
	canvas_material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	sprite.material = canvas_material
	
	# Apply normal maps to all frames
	var sprite_frames = sprite.sprite_frames
	if sprite_frames:
		for anim_name in sprite_frames.get_animation_names():
			var frame_count = sprite_frames.get_frame_count(anim_name)
			for frame in range(frame_count):
				var texture = sprite_frames.get_frame_texture(anim_name, frame)
				if texture:
					# Generate and apply normal map
					var normal_map = generate_normal_map(texture, strength)
					var canvas_texture = CanvasTexture.new()
					canvas_texture.diffuse_texture = texture
					canvas_texture.normal_texture = normal_map
					sprite_frames.set_frame(anim_name, frame, canvas_texture) 
