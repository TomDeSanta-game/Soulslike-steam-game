extends Area2D
class_name HitboxComponent

# Hitbox properties
@export var damage: float = 10.0
@export var knockback_force: float = 200.0
@export var hit_stun_duration: float = 0.2
@export var knockback_duration: float = 0.2
@export var one_shot: bool = false  # If true, deactivates after first hit
@export var damage_type: String = "physical"
@export var effects: Array[String] = []
@export var hit_sound: AudioStream
@export var hit_particles: PackedScene

var hitbox_owner: Node2D
var active: bool = true
var _has_hit: bool = false
var _hit_targets: Array[NodePath] = []

func _ready() -> void:
	# Connect area entered signal
	area_entered.connect(_on_area_entered)
	
	# Get owner reference (usually the character/weapon)
	hitbox_owner = get_parent()
	
	# Set collision layer and mask using C_Layers constants
	collision_layer = C_Layers.LAYER_HITBOX
	collision_mask = C_Layers.MASK_HITBOX
	
	# Ensure hitbox is active by default
	active = true
	show()
	
	add_to_group("Hitbox")

func get_damage() -> float:
	return damage

func _on_area_entered(area: Area2D) -> void:
	if not active or not area is HurtboxComponent:
		return
		
	var hurtbox = area as HurtboxComponent
	
	# Prevent self-damage
	if hurtbox.hurtbox_owner == hitbox_owner:
		return
	
	# Check if we've already hit this target
	if one_shot and _hit_targets.has(hurtbox.get_path()):
		return
	
	# Apply damage and effects
	if hurtbox.active:
		_hit_targets.append(hurtbox.get_path())
		SignalBus.hit_landed.emit(self, hurtbox)  # Use global signal only
		hurtbox.take_hit(self)
		
		# Handle one-shot behavior
		if one_shot:
			_has_hit = true
			deactivate()
		
		# Spawn hit effects
		_spawn_hit_effects(hurtbox.global_position)

func activate() -> void:
	active = true
	_has_hit = false
	_hit_targets.clear()
	show()

func deactivate() -> void:
	active = false
	hide()

func _spawn_hit_effects(hit_position: Vector2) -> void:
	# Play hit sound
	if hit_sound:
		var audio = AudioStreamPlayer2D.new()
		get_tree().root.add_child(audio)
		audio.stream = hit_sound
		audio.global_position = hit_position
		audio.play()
		audio.finished.connect(func(): audio.queue_free())
	
	# Spawn particles
	if hit_particles:
		var particles = hit_particles.instantiate()
		get_tree().root.add_child(particles)
		particles.global_position = hit_position
		if particles.has_method("restart"):
			particles.restart()
		# Auto-free particles after emission
		if particles is GPUParticles2D:
			await get_tree().create_timer(particles.lifetime).timeout
			particles.queue_free()
		elif particles is CPUParticles2D:
			await get_tree().create_timer(particles.lifetime).timeout
			particles.queue_free() 