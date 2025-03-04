@tool
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

## Generates a normal map from a texture using Sobel operators for height detection
## strength: Controls how pronounced the normal map effect is
static func generate_normal_map(texture: Texture2D, strength: float = 2.0) -> ImageTexture:
	var image = texture.get_image()
	var width = image.get_width()
	var height = image.get_height()
	
	# Create a new image for the normal map
	var normal_map = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	# Convert to grayscale for height map calculation
	var height_map = image.duplicate()
	height_map.convert(Image.FORMAT_L8)
	
	# Fill with default normal (facing forward) for transparent pixels
	for x in range(width):
		for y in range(height):
			var color = image.get_pixel(x, y)
			# If pixel is transparent, make normal map transparent too
			if color.a < 0.5:
				normal_map.set_pixel(x, y, Color(0.5, 0.5, 1.0, 0.0))
			else:
				# Default normal (will be overwritten for non-edge pixels)
				normal_map.set_pixel(x, y, Color(0.5, 0.5, 1.0, 1.0))
	
	# Apply Sobel operator to calculate normals for non-edge pixels
	for x in range(1, width - 1):
		for y in range(1, height - 1):
			var dx = 0.0
			var dy = 0.0
			
			# Skip fully transparent pixels
			if image.get_pixel(x, y).a < 0.5:
				continue
				
			# Apply Sobel operators
			for i in range(-1, 2):
				for j in range(-1, 2):
					var pixel = height_map.get_pixel(x + i, y + j).r
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

## Applies normal maps to all frames of an AnimatedSprite2D
## This creates reflection-ready sprites with normal maps
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
