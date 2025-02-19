extends CollectibleBase

# Since these are rare collectibles, they will restore full health and stamina
# No need for export vars since they'll always restore to max

const ITEM_ID = "celestial_tear"

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer

# Add autoload reference
@onready var inventory = get_node("/root/Inventory")

func _ready() -> void:
	super._ready()  # Call parent _ready first
	
	# Make sure the sprite has the shader material assigned
	if sprite:
		@warning_ignore("shadowed_variable_base_class")
		var material = ShaderMaterial.new()
		material.shader = preload("res://Shaders/Collectibles/glow_effect.gdshader")
		
		# Set default shader parameters
		material.set_shader_parameter("glow_color", Color(0.5, 0.8, 1.0, 0.6))  # Light blue glow
		material.set_shader_parameter("glow_intensity", 1.5)
		material.set_shader_parameter("glow_scale", 2.0)
		material.set_shader_parameter("pulse_speed", 3.0)
		material.set_shader_parameter("outer_radius", 0.4)
		material.set_shader_parameter("inner_radius", 0.1)
		material.set_shader_parameter("light_intensity", 0.5)
		
		sprite.material = material

func _process(_delta: float) -> void:
	if animation_player and !_is_collected:
		animation_player.play("ANIMATION")

func collect() -> void:
	if _is_collected:
		return

	# Add to inventory
	var item_data = {
		"id": ITEM_ID,
		"name": "Celestial Tear",
		"texture": load("res://assets/Sprite-0003.png"),
		"description": "A rare crystallized tear from the heavens. Restores full health and stamina when used.",
		"quantity": 1,
		"use_function": "use_celestial_tear"  # Add this to specify which function to call when used
	}
	
	inventory.add_item(ITEM_ID, item_data)

	# Call parent collect method to handle sound, effects and cleanup
	super.collect()

# New function that will be called when using the item from inventory
func use_celestial_tear() -> void:
	if player and player.has_method("get_max_health") and player.has_method("heal"):
		var max_health = player.get_max_health()
		player.heal(max_health)

	# Restore stamina to full if player has stamina system
	if player and player.has_method("get_max_stamina") and player.has_method("restore_stamina"):
		var max_stamina = player.get_max_stamina()
		player.restore_stamina(max_stamina)