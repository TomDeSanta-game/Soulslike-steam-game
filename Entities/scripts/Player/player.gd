extends CharacterBase

# Constants and Configuration
const STATS: Dictionary = {
	"MAX_MAGIC": 100.0,
	"MAGIC_COST": 10.0,
	"LIFESTEAL_PERCENT": 15.0,  # Percentage of damage dealt that will be returned as health
	"MIN_LIFESTEAL_AMOUNT": 1.0,  # Minimum amount of health restored per hit
	"MAX_LIFESTEAL_AMOUNT": 25.0,  # Maximum amount of health restored per hit
	"DASH_SPEED": 800.0,  # Speed during dash
	"DASH_DURATION": 0.2,  # Duration of dash in seconds
	"DASH_COOLDOWN": 0.5  # Time before can dash again
}

const ANIMATIONS: Dictionary = {
	"IDLE": "Idle",
	"RUN": "Run",
	"JUMP": "Jump",
	"ATTACK": "Attack",
	"CROUCH": "Crouch",
	"CROUCH_ATTACK": "Crouch_Attack",
	"HURT": "Hurt",
	"JUMP_ATTACK": "Jump_Attack",
	"RUN_ATTACK": "Run_Attack"
}

# Node references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var label: Label = $Label
@onready var shooter: Shooter = $Shooter
@onready var health_bar: ProgressBar = $ProgressBar
@onready var camera: Camera2D = $Camera2D

# Types Global
@onready var types: Types = Types.new()

# Timers
@onready var time_taken_damage_timer: Timer = $Timers/TimeTakenDamageTimer
@onready var hurt_timer: Timer = $Timers/HurtTimer
@onready var attack_timer: Timer = $Timers/AttackTimer
@onready var crouch_attack_timer: Timer = $Timers/CrouchAttackTimer
@onready var death_timer: Timer = $Timers/DeathTimer

# Player Group
@export_group("Shaders")
@export var _shader_material: ShaderMaterial
@export var _death_shader_material: ShaderMaterial
@export var _dash_shader_material: ShaderMaterial

# Player state
var magic: float = STATS.MAX_MAGIC
var direction: float = 0.0
var is_attacking: bool = false
var is_crouching: bool = false
var current_state: Types.CharacterState = Types.CharacterState.IDLE

# Fade Variables
var fade_duration: float = 2.0  # Duration of the fade effect
var fade_timer: float = 0.0  # Timer for the fade effect
var is_fading: bool = false  # Track if the fade effect is active

const MOVEMENT_SPEEDS = {
	"WALK": 300.0,
	"RUN": 450.0,
	"CROUCH": 150.0,
}

# Health Variables
var current_health: float
var max_health: float
var health_percent: float
var health_regen_rate: float = 0.5
var can_heal: bool = false

# Damage Shader
var effect_duration: float = 1.66666666667  # Duration of the effect
var effect_timer: float = 0.0  # Timer for the effect

# FrameData System
@onready var frame_data_component: FrameDataComponent = %FrameDataComponent

var current_animation: String = ""
var current_frame: int = 0

# Jump-Cutting System
var is_jump_held: bool = false
var is_jump_active: bool = false

# Jump Timer
@onready var jump_timer: Timer = Timer.new()

# State Machine
@onready var state_machine: PlayerStateMachine = PlayerStateMachine.new()

# Acceleration and Deceleration
var acceleration_frames: int = 12
var deceleration_frames: int = 18
var deceleration_counter: int = 0
var current_acceleration_frame: int = 0
var target_speed: float = 0.0

# Debug Colors
const DEBUG_COLORS = {"HITBOX": Color(1, 0, 0, 0.5), "HURTBOX": Color(0, 1, 0, 0.5)}

@onready var hitbox: HitboxComponent = %Hitbox
@onready var hurtbox: HurtboxComponent = %Hurtbox

# Dash Variables
var can_dash: bool = true
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0


func _ready() -> void:
	super._ready()  # Call parent _ready to initialize health system
	types.player = self

	# Initialize health system first
	health_system = HealthSystem.new()
	add_child(health_system)
	health_system._health_changed.connect(_on_health_changed)
	health_system._character_died.connect(_on_character_died)
	health_system.set_vigour(10)

	# Get initial health values
	current_health = health_system.get_health()
	max_health = health_system.get_max_health()
	health_percent = health_system.get_health_percentage()

	# Setup health bar
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.min_value = 0

	# Setup hitbox and hurtbox with correct layers
	if hitbox:
		hitbox.hitbox_owner = self
		hitbox.damage = 15.0
		hitbox.knockback_force = 200.0
		hitbox.hit_stun_duration = 0.2
		hitbox.collision_layer = 4  # Player layer
		hitbox.collision_mask = 2  # Enemy layer (to detect enemy hurtboxes)
		hitbox.add_to_group("Hitbox")
		hitbox.active = true  # Keep hitbox always active

	if hurtbox:
		hurtbox.hurtbox_owner = self
		hurtbox.collision_layer = 4  # Player layer
		hurtbox.collision_mask = 2  # Enemy layer (to detect enemy hitboxes)
		hurtbox.active = true  # Keep hurtbox always active

	# Add self to Player group
	add_to_group("Player")

	add_child(state_machine)

	add_child(jump_timer)

	jump_timer.wait_time = 1.0
	jump_timer.one_shot = true
	jump_timer.timeout.connect(_jump_timer_timeout)

	animated_sprite.material = _shader_material

	base_run_speed = MOVEMENT_SPEEDS.RUN
	base_crouch_speed = MOVEMENT_SPEEDS.CROUCH

	frame_data_component.sprite = animated_sprite
	frame_data_component.hitbox = hitbox
	frame_data_component.hurtbox = hurtbox

	# Connect animated sprite signals
	animated_sprite.animation_changed.connect(_on_animation_changed)
	animated_sprite.animation_finished.connect(_on_animation_finished)

	_setup_commands()
	_connect_signals()

	state_machine.init(self)

	# Connect state machine signals
	state_machine.attack_started.connect(_on_attack_started)
	state_machine.attack_ended.connect(_on_attack_ended)

	# Connect frame changed signal for redrawing
	if !animated_sprite.frame_changed.is_connected(_on_frame_changed):
		animated_sprite.frame_changed.connect(_on_frame_changed)

	# Connect hitbox and hurtbox signals properly
	if hitbox and !hitbox.hit_landed.is_connected(_on_hit_landed):
		hitbox.hit_landed.connect(_on_hit_landed)
	if hurtbox:
		if !hurtbox.hit_taken.is_connected(_on_hit_taken):
			hurtbox.hit_taken.connect(_on_hit_taken)

	# Initialize frame data
	_frame_data_init()
	frame_data_component.update_frame_data()  # Initial frame data update


func _process(delta: float) -> void:
	if effect_timer > 0.0:
		effect_timer -= delta
		# Calculate the progress of the effect (0.0 to 1.0)
		var progress = 1.0 - (effect_timer / effect_duration)
		_shader_material.set_shader_parameter("effect_progress", progress)
	else:
		# Reset the effect progress when the timer is done
		_shader_material.set_shader_parameter("effect_progress", 0.0)

	if is_fading:
		fade_timer += delta
		# Calculate the fade progress (0.0 to 1.0)
		var progress = min(fade_timer / fade_duration, 1.0)
		_death_shader_material.set_shader_parameter("fade_progress", progress)

		# If the fade is complete, queue free the player
		if progress >= 1.0:
			pass

	_health_regen(delta)
	_update_player_state()
	_update_ui()
	_update_health_bar()


func _physics_process(delta: float) -> void:
	if !is_on_floor():
		velocity.y += Types.GRAVITY_CONSTANT * delta

	# Jump cutting logic
	if is_jump_active and not is_jump_held and velocity.y < 0:
		velocity.y = 0  # Stop upward movement if jump button is released
		is_jump_active = false

	# Handle dash cooldown
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer <= 0:
			can_dash = true

	# Handle active dash
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
		else:
			# Apply dash velocity
			var dash_direction = -1.0 if animated_sprite.flip_h else 1.0
			velocity.x = dash_direction * STATS.DASH_SPEED
			# Disable gravity during dash
			velocity.y = 0

	if not is_dashing:
		_handle_movement()
	move_and_slide()


# NOTE: Main Frame Data Initialization ( Player )
func _frame_data_init() -> void:
	# Initialize frame data component with all required nodes
	if frame_data_component and animated_sprite and hitbox and hurtbox:
		frame_data_component.sprite = animated_sprite
		frame_data_component.hitbox = hitbox
		frame_data_component.hurtbox = hurtbox

		# Connect animation signals only once
		if !animated_sprite.frame_changed.is_connected(_on_frame_changed):
			animated_sprite.frame_changed.connect(_on_frame_changed)
		if !animated_sprite.animation_changed.is_connected(_on_animation_changed):
			animated_sprite.animation_changed.connect(_on_animation_changed)
		if !animated_sprite.animation_finished.is_connected(_on_animation_finished):
			animated_sprite.animation_finished.connect(_on_animation_finished)
	else:
		push_error("Player: Missing required nodes for frame data initialization")


func _setup_commands() -> void:
	LimboConsole.register_command(_die)


func _unhandled_input(event: InputEvent) -> void:
	_handle_input(event)


func _trigger_effect() -> void:
	effect_timer = effect_duration


# Update the healthbar
func _update_health_bar() -> void:
	health_bar.value = current_health


# Movement System
func _handle_movement() -> void:
	direction = Input.get_axis("LEFT", "RIGHT")
	var speed = _get_current_speed()

	if current_state == Types.CharacterState.IDLE or current_state == Types.CharacterState.MOVE:
		if direction != 0:
			deceleration_counter = 0  # Reset deceleration counter when moving
			target_speed = speed * sign(direction)
			if current_acceleration_frame < acceleration_frames:
				current_acceleration_frame += 1
			var acceleration_factor = float(current_acceleration_frame) / acceleration_frames
			velocity.x = lerp(velocity.x, target_speed, acceleration_factor)
		else:
			current_acceleration_frame = 0  # Reset acceleration when not moving
			if abs(velocity.x) > 0:
				deceleration_counter = min(deceleration_counter + 1, deceleration_frames)
				var deceleration_progress = float(deceleration_counter) / deceleration_frames
				velocity.x = lerp(velocity.x, 0.0, deceleration_progress)

	_update_sprite_direction()
	_update_movement_state()


func _get_current_speed() -> float:
	# Return different speeds based on current state
	if is_crouching:
		return base_crouch_speed
	return base_run_speed


func _update_movement_state() -> void:
	if abs(velocity.x) > 5.0:  # Small threshold to avoid floating point issues
		current_state = Types.CharacterState.MOVE
	else:
		velocity.x = 0  # Snap to zero when very slow
		current_state = Types.CharacterState.IDLE


func _reset_acceleration() -> void:
	current_acceleration_frame = 0
	target_speed = 0.0


func _update_sprite_direction() -> void:
	if direction != 0:
		var was_flipped = animated_sprite.flip_h
		animated_sprite.flip_h = direction < 0
		if was_flipped != animated_sprite.flip_h:
			queue_redraw()  # Only redraw if flip state changed


# State Management
func _update_player_state() -> void:
	is_attacking = _is_attack_animation()
	is_crouching = animated_sprite.animation == ANIMATIONS.CROUCH


func _is_attack_animation() -> bool:
	return (
		animated_sprite.animation
		in [
			ANIMATIONS.ATTACK,
			ANIMATIONS.JUMP_ATTACK,
			ANIMATIONS.RUN_ATTACK,
			ANIMATIONS.CROUCH_ATTACK
		]
	)


# Input Handling
func _handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("JUMP") and is_on_floor():
		is_jump_held = true  # Jump button is being held
		_handle_jump()
	elif event.is_action_released("JUMP"):
		is_jump_held = false  # Jump button is released

	# Handle dash input
	if event.is_action_pressed("DASH") and can_dash and not is_dashing:
		_start_dash()

	if event.is_action_released("ATTACK"):
		if is_on_floor():
			if abs(velocity.x) > 0:  # If moving on ground
				state_machine.dispatch(&"run_attack")
			else:
				state_machine.dispatch(&"attack")
		else:
			state_machine.dispatch(&"jump_attack")
	elif event.is_action_released("CROUCH"):
		state_machine.dispatch(&"crouch")
	elif event.is_action_released("SHOOT"):
		_shoot()

	# Health
	if event.is_action_released("HEALTH_DOWN"):
		take_damage(10.0)
	elif event.is_action_released("HEAL"):
		_heal(10.0)
	elif event.is_action_released("DIE"):
		take_damage(100.0)


func _handle_jump() -> void:
	if is_on_floor():
		velocity.y = jump_power
		is_jump_held = true
		is_jump_active = true  # Jump is active
		jump_timer.start()  # Start the jump timer


# Combat System
func _shoot() -> void:
	var dir = Vector2.LEFT if animated_sprite.flip_h else Vector2.RIGHT
	shooter.shoot(dir)


# Override parent's die function
func _die() -> void:
	state_machine.set_active(false)

	set_physics_process(false)

	# Switch to the death shader material
	animated_sprite.material = _death_shader_material

	# Screen Shake
	camera.shake(10, 0.5, 0.9)

	# Death Sound
	SoundManager.play_sound(Sound.death, "SFX")

	# Start the fade effect
	is_fading = true
	fade_timer = 0.0

	# Hide UI elements
	label.hide()
	health_bar.hide()

	death_timer.start()
	$GameOverLabel.show()


func _on_death_timer_timeout() -> void:
	hide()


# Magic System
func _handle_magic(healing_amount: float) -> void:
	if magic >= STATS.MAGIC_COST:
		health_system.heal(healing_amount)
		magic = max(0, magic - STATS.MAGIC_COST)


# Take Damage
func take_damage(damage_amount: float) -> void:
	current_health -= damage_amount
	current_health = clamp(current_health, 0.0, max_health)
	health_percent = (current_health / max_health) * 100.0

	if current_health <= 0:
		_die()
	else:
		# Play hurt animation and sound
		animated_sprite.play(ANIMATIONS.HURT)
		SoundManager.play_sound(Sound.oof, "SFX")

		# Start invincibility
		hurtbox.start_invincibility()

		# Update health bar
		health_bar.value = current_health

		# Screen shake effect
		camera.shake(5, 0.2, 0.8)

		# Start damage shader effect
		effect_timer = 0.0
		animated_sprite.material = _shader_material
		animated_sprite.material.set_shader_parameter("effect_progress", 1.0)


# Health the health
func _heal(amount: float) -> void:
	current_health += amount
	current_health = clamp(current_health, 0.0, max_health)
	health_percent = (current_health / max_health) * 100.0

	_update_health_bar()
	_check_health()


# Health regeneration
func _health_regen(delta: float) -> void:
	if current_health == max_health or not can_heal:
		return  # Exit

	current_health = min(current_health + health_regen_rate * delta, max_health)


# Check for health
func _check_health() -> void:
	if current_health == 0.0:
		_die()


# UI System
func _update_ui() -> void:
	label.text = (
		"Class: %s\nFPS: %s\nHealth: %s/%s (%.1f%%)\nAnimation: %s"
		% [
			"None",
			Engine.get_frames_per_second(),
			current_health,
			max_health,
			health_percent,
			animated_sprite.animation
		]
	)


func _connect_signals() -> void:
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	hurt_timer.timeout.connect(_on_hurt_timer_timeout)
	crouch_attack_timer.timeout.connect(_on_crouch_attack_timer_timeout)


# Signal Callbacks
func _on_attack_timer_timeout() -> void:
	state_machine.dispatch(&"state_ended")


func _on_crouch_attack_timer_timeout() -> void:
	state_machine.dispatch(&"crouch")


func _on_hurt_timer_timeout() -> void:
	state_machine.dispatch(&"state_ended")


func _on_time_taken_damage_timer_timeout() -> void:
	can_heal = true


func _jump_timer_timeout() -> void:
	is_jump_held = false
	is_jump_active = false
	velocity.y = 0


func _on_hit_landed(target_hurtbox: HurtboxComponent) -> void:
	if target_hurtbox.hurtbox_owner and target_hurtbox.hurtbox_owner.is_in_group("Enemy"):
		# Play hit effect or sound
		SoundManager.play_sound(Sound.hit, "SFX")
		# Apply lifesteal if enabled
		_apply_lifesteal(hitbox.damage)


func _on_hit_taken(attacker_hitbox: HitboxComponent) -> void:
	if attacker_hitbox.hitbox_owner and attacker_hitbox.hitbox_owner.is_in_group("Enemy"):
		take_damage(attacker_hitbox.damage)


func _on_hurtbox_area_entered(_area: Area2D) -> void:
	pass  # Let hit_taken handle the damage


func _on_animation_changed() -> void:
	if animated_sprite.animation == ANIMATIONS.IDLE:
		animated_sprite.play(ANIMATIONS.IDLE)
	if animated_sprite.animation == ANIMATIONS.RUN:
		animated_sprite.play(ANIMATIONS.RUN)
	if animated_sprite.animation == ANIMATIONS.RUN_ATTACK:
		animated_sprite.play(ANIMATIONS.RUN_ATTACK)
	if animated_sprite.animation == ANIMATIONS.CROUCH:
		animated_sprite.play(ANIMATIONS.CROUCH, 1.0, false)
	if animated_sprite.animation == ANIMATIONS.CROUCH_ATTACK:
		animated_sprite.play(ANIMATIONS.CROUCH_ATTACK)
	if animated_sprite.animation == ANIMATIONS.JUMP:
		animated_sprite.play(ANIMATIONS.JUMP)
	if animated_sprite.animation == ANIMATIONS.JUMP_ATTACK:
		animated_sprite.play(ANIMATIONS.JUMP_ATTACK)
	if animated_sprite.animation == ANIMATIONS.ATTACK:
		animated_sprite.play(ANIMATIONS.ATTACK)


func _on_animation_finished() -> void:
	if animated_sprite.animation == ANIMATIONS.RUN:
		animated_sprite.play(ANIMATIONS.IDLE)
	if animated_sprite.animation == ANIMATIONS.RUN_ATTACK:
		animated_sprite.play(ANIMATIONS.RUN)
	if animated_sprite.animation == ANIMATIONS.CROUCH_ATTACK:
		animated_sprite.play(ANIMATIONS.CROUCH, 1.0, false)
	if animated_sprite.animation == ANIMATIONS.JUMP:
		animated_sprite.play(ANIMATIONS.IDLE)
	if animated_sprite.animation == ANIMATIONS.JUMP_ATTACK:
		animated_sprite.play(ANIMATIONS.JUMP)
	if animated_sprite.animation == ANIMATIONS.ATTACK:
		animated_sprite.play(ANIMATIONS.IDLE)


func _on_frame_changed() -> void:
	frame_data_component.update_frame_data()
	queue_redraw()


# Lifesteal System
func _apply_lifesteal(damage_dealt: float) -> void:
	var lifesteal_amount = damage_dealt * STATS.LIFESTEAL_PERCENT / 100.0
	lifesteal_amount = clamp(
		lifesteal_amount, STATS.MIN_LIFESTEAL_AMOUNT, STATS.MAX_LIFESTEAL_AMOUNT
	)

	if lifesteal_amount > 0:
		# Visual feedback for lifesteal
		_trigger_lifesteal_effect()
		# Play lifesteal sound
		SoundManager.play_sound(Sound.heal, "SFX")
		# Apply the healing
		_heal(lifesteal_amount)


# Visual feedback for lifesteal
func _trigger_lifesteal_effect() -> void:
	# Add a green flash or healing effect using the shader
	_shader_material.set_shader_parameter("lifesteal_active", true)
	await get_tree().create_timer(0.2).timeout
	_shader_material.set_shader_parameter("lifesteal_active", false)


func _on_health_changed(new_health: float, new_max_health: float) -> void:
	current_health = new_health
	max_health = new_max_health
	health_percent = health_system.get_health_percentage()
	health_bar.value = current_health


func _on_character_died() -> void:
	_die()


func _on_attack_started() -> void:
	frame_data_component.update_frame_data()


func _on_attack_ended() -> void:
	frame_data_component.clear_active_boxes()


func _start_dash() -> void:
	is_dashing = true
	can_dash = false
	dash_timer = STATS.DASH_DURATION
	dash_cooldown_timer = STATS.DASH_COOLDOWN

	# Switch to dash shader material
	animated_sprite.material = _dash_shader_material

	# Play dash sound
	SoundManager.play_sound(Sound.dash, "SFX")

	# Enhanced screen shake for dash feedback
	camera.shake(8, 0.15, 0.8)  # Increased intensity and duration

	# Brief pause for impact - using get_parent() to get the actual CharacterBody2D node
	var player_node = self
	PauseManager.pause(player_node)  # Pause the player
	await get_tree().create_timer(0.1).timeout  # Wait for 0.1 seconds
	PauseManager.unpause(player_node)  # Unpause the player

	# Switch back to normal shader after dash starts
	animated_sprite.material = _shader_material
