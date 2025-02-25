extends CollectibleBase

# Since these are rare collectibles, they will restore full health and stamina
# No need for export vars since they'll always restore to max

const ITEM_ID: String = "celestial_tear"
const SOULS_REWARD: int = 50000  # Exactly 50,000 souls (5 digits)
const XP_REWARD: int = 100000    # Exactly 100,000 XP (6 digits)

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
		var shader_material = ShaderMaterial.new()
		shader_material.shader = preload("res://Shaders/Collectibles/glow_effect.gdshader")
		
		# Core colors
		shader_material.set_shader_parameter("inner_light", Color(1.0, 0.95, 0.7, 1.0))  # Warm divine core
		shader_material.set_shader_parameter("outer_light", Color(0.4, 0.6, 1.0, 1.0))   # Celestial aura
		shader_material.set_shader_parameter("void_color", Color(0.0, 0.0, 0.0, 1.0))    # Pure black
		shader_material.set_shader_parameter("void_accent", Color(0.2, 0.2, 0.2, 1.0))   # Dark gray
		
		# Animation timing
		shader_material.set_shader_parameter("cycle_speed", 0.7)        # Overall effect speed
		shader_material.set_shader_parameter("void_duration", 1.0)      # Dark phase duration
		shader_material.set_shader_parameter("transition_speed", 1.5)   # Phase transition speed
		
		# Effect parameters
		shader_material.set_shader_parameter("energy_rings", 4.0)       # Number of energy rings
		shader_material.set_shader_parameter("vortex_strength", 1.0)    # Rotation intensity
		shader_material.set_shader_parameter("light_intensity", 1.5)    # Brightness of light phase
		
		# Pattern controls
		shader_material.set_shader_parameter("spiral_count", 6.0)       # Number of spiral arms
		shader_material.set_shader_parameter("spiral_tightness", 5.0)   # Spiral density
		shader_material.set_shader_parameter("distortion_strength", 0.3) # Pattern distortion
		
		# Void phase parameters
		shader_material.set_shader_parameter("void_ring_count", 3.0)    # Number of void rings
		shader_material.set_shader_parameter("void_ring_speed", 0.5)    # Ring expansion speed
		
		sprite.material = shader_material

func _process(_delta: float) -> void:
	if animation_player and !_is_collected:
		animation_player.play("ANIMATION")

func collect() -> void:
	if _is_collected:
		return

	_is_collected = true

	# Add XP first (before souls to ensure proper level up calculation)
	if xp_system:
		# Add XP with verification
		xp_system.add_xp(XP_REWARD)

	# Add souls (independent of XP)
	if souls_system:
		souls_system.add_souls(SOULS_REWARD)

	# Add to inventory
	var item_data = {
		"id": ITEM_ID,
		"name": "Celestial Tear",
		"texture": load("res://assets/Sprite-0003.png"),
		"description": "A divine crystallized tear from the heavens, radiating pure celestial energy. Restores full health and stamina when used.",
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
		var P = players[0]
		
		# Heal to full health silently by directly updating health system
		if P.has_method("get_max_health"):
			var max_health = P.get_max_health()
			if P.health_system:
				P.health_system.set_health_silent(max_health)

		# Restore stamina to full
		if P.has_method("get_max_stamina") and P.has_method("restore_stamina"):
			var max_stamina = P.get_max_stamina()
			P.restore_stamina(max_stamina)