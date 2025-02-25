class_name WereWolf
extends EnemyBase

@export_group("Werewolf Properties")
@export var patrol_speed: float = 150.0

@onready var attack_detector: HitboxComponent = $HitBox

var attack_enabled: bool = true

func _ready() -> void:
	super._ready()  # This will call _setup_combat_components
	_initialize_werewolf()
	_setup_console_commands()
	
	# Ensure hitbox is active after setup
	if enemy_hitbox:
		enemy_hitbox.active = true

	# Frame data setup will be called by parent class after one frame


func _initialize_werewolf() -> void:
	initial_vigour = 10
	base_run_speed = 100.0
	jump_power = -400.0
	attack_damage = 10.0
	attack_range = 50.0
	attack_cooldown = 1.0

	# Setup hitbox for werewolf attacks
	if enemy_hitbox:
		enemy_hitbox.damage = attack_damage
		enemy_hitbox.knockback_force = 200.0
		enemy_hitbox.hit_stun_duration = 0.2
		enemy_hitbox.collision_layer = 2  # Enemy layer
		enemy_hitbox.collision_mask = 4   # Player layer (to detect player hurtboxes)
		enemy_hitbox.active = true  # Keep hitbox always active

	# Setup hurtbox for werewolf body
	if enemy_hurtbox:
		enemy_hurtbox.collision_layer = 2  # Enemy layer
		enemy_hurtbox.collision_mask = 4   # Player layer (to detect player hitboxes)
		enemy_hurtbox.active = true


func _setup_frame_data() -> void:
	# Call parent's setup first
	super._setup_frame_data()
	
	if not frame_data_component:
		push_error("FrameDataComponent not found in werewolf")
		return
		
	if not animated_sprite:
		push_error("AnimatedSprite2D not found in werewolf")
		return

	# Keep base hitbox active but still use frame data for attack animations
	if enemy_hitbox:
		enemy_hitbox.active = true
		frame_data_component.hitbox = enemy_hitbox
		frame_data_component.update_frame_data()  # Initial frame data update

	if enemy_hurtbox:
		enemy_hurtbox.active = true
		frame_data_component.hurtbox = enemy_hurtbox


func _physics_process(delta: float) -> void:
	if !is_on_floor():
		velocity.y += Types.GRAVITY_CONSTANT * delta
	_handle_wall_collision()


func _handle_wall_collision() -> void:
	if is_on_floor() and is_on_wall():
		velocity.y = jump_power


func _update_animation() -> void:
	if not is_on_floor():
		animated_sprite.play(&"Jump")
	elif velocity.x != 0:
		animated_sprite.play(&"Run")
	else:
		animated_sprite.play(&"Idle")


func _setup_console_commands() -> void:
	LimboConsole.register_command(_change_direction)
	LimboConsole.register_command(cks)


func _change_direction(new_direction: int) -> void:
	current_direction = sign(new_direction)
	Log.debug("Direction set to: " + str(current_direction))


func cks() -> void:
	LimboConsole.clear_console()


# Override parent's die function
func die() -> void:
	animated_sprite.play(&"Death")
	
	# Disable physics and collision
	set_physics_process(false)
	set_process(false)
	
	# Clear frame data and disable all hitboxes and hurtboxes
	if frame_data_component:
		frame_data_component.clear_active_boxes()
	
	for box in hitboxes:
		if box:
			box.queue_free()
	
	for box in hurtboxes:
		if box:
			box.queue_free()
	
	# Wait for death animation
	await animated_sprite.animation_finished
	queue_free()


# Override parent's combat functions for werewolf-specific behavior
func _on_hit_landed(_hitbox_node: Node, target_hurtbox: Node) -> void:
	super._on_hit_landed(_hitbox_node, target_hurtbox)
	
	# Add werewolf-specific hit effects
	if target_hurtbox is HurtboxComponent and target_hurtbox.hurtbox_owner.is_in_group("Player"):
		# Play attack sound
		SoundManager.play_sound(Sound.monster_attack, "SFX")
		
		# Add screen shake
		if target_hurtbox.hurtbox_owner.has_node("Camera2D"):
			var camera = target_hurtbox.hurtbox_owner.get_node("Camera2D")
			camera.shake(15.0, 0.3, 0.7)


func _on_hit_taken(attacker_hitbox: Node, _defender_hurtbox: Node) -> void:
	super._on_hit_taken(attacker_hitbox, _defender_hurtbox)
	
	# Add werewolf-specific hurt effects
	if attacker_hitbox is HitboxComponent and attacker_hitbox.hitbox_owner.is_in_group("Player"):
		# Play hurt animation with blood effect
		animated_sprite.play(&"Hurt")
		
		# Add screen shake
		if attacker_hitbox.hitbox_owner.has_node("Camera2D"):
			var camera = attacker_hitbox.hitbox_owner.get_node("Camera2D")
			camera.shake(10.0, 0.2, 0.6)
