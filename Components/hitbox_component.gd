extends Area2D
class_name HitboxComponent

signal hit_landed(hurtbox: HurtboxComponent)

# Hitbox properties
@export var damage: float = 10.0
@export var knockback_force: float = 100.0
@export var knockback_duration: float = 0.2
@export var hit_stun_duration: float = 0.1
@export var active: bool = true
@export var one_shot: bool = false  # If true, deactivates after first hit

# Optional properties for special attacks
@export var damage_type: String = "physical"
@export var effects: Array[String] = []
@export var hit_sound: AudioStream
@export var hit_particles: PackedScene

# Owner reference
var hitbox_owner: Node

var _has_hit: bool = false
var _hit_targets: Array[NodePath] = []

func _ready() -> void:
	# Connect area entered signal
	area_entered.connect(_on_area_entered)
	
	# Get owner reference (usually the character/weapon)
	hitbox_owner = get_parent()
	
	# Set collision layer and mask
	collision_layer = 2  # Layer 2 for hitboxes
	collision_mask = 4   # Layer 3 for hurtboxes


func activate() -> void:
	active = true
	_has_hit = false
	_hit_targets.clear()
	show()


func deactivate() -> void:
	active = false
	hide()


func _on_area_entered(area: Area2D) -> void:
	if not active or not area is HurtboxComponent:
		return
		
	var hurtbox = area as HurtboxComponent
	
	# Check if we've already hit this target
	if one_shot and _hit_targets.has(hurtbox.get_path()):
		return
	
	# Calculate knockback direction
	var knockback_dir = (hurtbox.global_position - global_position).normalized()
	
	# Apply damage and effects
	if hurtbox.take_hit(self, knockback_dir):
		_hit_targets.append(hurtbox.get_path())
		hit_landed.emit(hurtbox)
		
		# Handle one-shot behavior
		if one_shot:
			_has_hit = true
			deactivate()
		
		# Spawn hit effects
		_spawn_hit_effects(hurtbox.global_position)


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