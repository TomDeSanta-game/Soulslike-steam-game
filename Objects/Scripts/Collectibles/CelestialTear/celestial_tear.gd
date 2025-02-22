extends CollectibleBase

# Since these are rare collectibles, they will restore full health and stamina
# No need for export vars since they'll always restore to max

const ITEM_ID: String = "celestial_tear"
const SOULS_REWARD: int = 50000  # 50,000 souls
const XP_REWARD: int = 100000    # 100,000 XP

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var souls_system = get_node("/root/SoulsSystem")
@onready var xp_system = get_node("/root/XPSystem")

# Add autoload reference
@onready var inventory = get_node("/root/Inventory")

func _ready() -> void:
	super._ready()  # Call parent _ready first
	
	# Configure this collectible to NOT give souls through parent class
	gives_souls = false  # We'll handle souls manually in collect()
	
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

	_is_collected = true

	# Add souls directly through the souls system
	if souls_system:
		souls_system.add_souls(SOULS_REWARD)
		
		# Try to level up instantly with the new souls
		if xp_system:
			xp_system.try_level_up()

	# Add to inventory
	var item_data = {
		"id": ITEM_ID,
		"name": "Celestial Tear",
		"texture": load("res://assets/Sprite-0003.png"),
		"description": "A rare crystallized tear from the heavens. Restores full health and stamina when used.",
		"use_function": "use_celestial_tear"
	}
	
	inventory.add_item(ITEM_ID, item_data)

	# Play collect sound
	SoundManager.play_sound(Sound.collect, "SFX")
	
	SignalBus.collectible_collected.emit(self)
	queue_free()

# Function that will be called when using the item from inventory
func use_celestial_tear() -> void:
	# Get player reference
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		var player = players[0]
		
		# Heal to full health silently by directly updating health system
		if player.has_method("get_max_health"):
			var max_health = player.get_max_health()
			if player.health_system:
				player.health_system.set_health_silent(max_health)

		# Restore stamina to full
		if player.has_method("get_max_stamina") and player.has_method("restore_stamina"):
			var max_stamina = player.get_max_stamina()
			player.restore_stamina(max_stamina)