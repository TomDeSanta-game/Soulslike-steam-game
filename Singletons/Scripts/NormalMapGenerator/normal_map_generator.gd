extends Node

const SOBEL_X = [
	-1, 0, 1,
	-2, 0, 2,
	-1, 0, 1
]

const SOBEL_Y = [
	-1, -2, -1,
	0, 0, 0,
	1, 2, 1
]

static func generate_normal_map(texture: Texture2D, strength: float = 2.0) -> ImageTexture:
	var image = texture.get_image()
	var width = image.get_width()
	var height = image.get_height()
	
	# Create a new image for the normal map
	var normal_map = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	# Convert to grayscale and calculate height map
	image.convert(Image.FORMAT_L8)
	
	for x in range(1, width - 1):
		for y in range(1, height - 1):
			var dx = 0.0
			var dy = 0.0
			
			# Apply Sobel operators
			for i in range(-1, 2):
				for j in range(-1, 2):
					var pixel = image.get_pixel(x + i, y + j).r
					var sobel_idx = (i + 1) + (j + 1) * 3
					
					dx += pixel * SOBEL_X[sobel_idx]
					dy += pixel * SOBEL_Y[sobel_idx]
			
			# Calculate normal vector
			dx *= strength
			dy *= strength
			var dz = 1.0
			
			var normal = Vector3(dx, dy, dz).normalized()
			
			# Convert from [-1, 1] to [0, 1] range
			normal = (normal + Vector3.ONE) * 0.5
			
			# Set the normal map pixel
			normal_map.set_pixel(x, y, Color(normal.x, normal.y, normal.z, 1.0))
	
	# Fill edges with neighboring pixels
	for x in range(width):
		normal_map.set_pixel(x, 0, normal_map.get_pixel(x, 1))
		normal_map.set_pixel(x, height - 1, normal_map.get_pixel(x, height - 2))
	
	for y in range(height):
		normal_map.set_pixel(0, y, normal_map.get_pixel(1, y))
		normal_map.set_pixel(width - 1, y, normal_map.get_pixel(width - 2, y))
	
	return ImageTexture.create_from_image(normal_map)

static func apply_normal_maps_to_animated_sprite(_sprite: AnimatedSprite2D, _strength: float = 2.0) -> void:
	# This function is now deprecated - normal maps are applied directly in the player script
	# This is just a stub to avoid errors when called
	pass

# The following signal handlers are no longer used but kept for reference
# They can be safely removed if needed
#static func _on_frame_changed(sprite: AnimatedSprite2D, strength: float) -> void:
#	_update_sprite_normal_map(sprite, strength)
#
#static func _on_animation_changed(sprite: AnimatedSprite2D, strength: float) -> void:
#	_update_sprite_normal_map(sprite, strength)
#
#static func _update_sprite_normal_map(sprite: AnimatedSprite2D, strength: float) -> void:
#	var sprite_frames = sprite.sprite_frames
#	if not sprite_frames:
#		return
#		
#	var current_animation = sprite.animation
#	var current_frame = sprite.frame
#	
#	if current_animation and current_frame >= 0:
#		var texture = sprite_frames.get_frame_texture(current_animation, current_frame)
#		if texture:
#			var normal_map = generate_normal_map(texture, strength)
#			sprite.normal_map = normal_map 