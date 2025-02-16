extends Node2D

signal bonfire_activated(bonfire: Node2D)

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var interaction_area: Area2D = $InteractionArea
@onready var particles: GPUParticles2D = $Particles
@onready var light: PointLight2D = $Light
@onready var save_engine: Node = get_node("/root/SaveEngine")

var is_active: bool = false
var spawn_offset: Vector2 = Vector2(-5, 0)  # 5 pixels to the left of bonfire

func _ready() -> void:
	interaction_area.body_entered.connect(_on_interaction_area_entered)
	if not animation_player.has_animation("idle"):
		push_error("Bonfire: Missing idle animation")
	else:
		animation_player.play("idle")


func _on_interaction_area_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not is_active:
		activate_bonfire()


func activate_bonfire() -> void:
	is_active = true
	
	# Visual feedback
	particles.emitting = true
	light.energy = 2.0  # Increase light intensity
	
	# Play activation sound
	SoundManager.play_sound(Sound.bonfire_lit, "SFX")
	
	# Save checkpoint
	save_engine.set_last_bonfire(global_position + spawn_offset)
	
	# Heal the player (optional)
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_method("_heal"):
		player._heal(player.max_health)  # Full heal
	
	# Emit signal for other systems
	bonfire_activated.emit(self)


func get_spawn_position() -> Vector2:
	return global_position + spawn_offset