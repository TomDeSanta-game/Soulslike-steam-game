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
	"DASH_COOLDOWN": 0.5,  # Time before can dash again
	"MAX_STAMINA": 100.0,
	"STAMINA_REGEN_RATE": 20.0,  # Stamina points per second
	"ATTACK_STAMINA_COST": 10.0,
	"RUN_ATTACK_STAMINA_COST": 20.0,
	"JUMP_STAMINA_COST": 35.0,
	"RUN_STAMINA_DRAIN_RATE": 5.55,  # Drains full stamina if running too long
	"COYOTE_TIME": 0.15,  # 150ms of coyote time
}

const ANIMATIONS: Dictionary = {
	"IDLE": "Idle",
	"RUN": "Run",
	"JUMP": "Jump",
	"ATTACK": "Attack",
	"ATTACK_COMBO": "Attack_Combo",
	"CROUCH": "Crouch",
	"CROUCH_ATTACK": "Crouch_Attack",
	"CROUCH_RUN": "Crouch_Run",
	"CROUCH_TRANSITION": "Crouch_Start_&_End",
	"DASH": "Dash",
	"DEATH": "Death",
	"FALL": "Fall",
	"HURT": "Hurt",
	"JUMP_ATTACK": "Jump_Attack",
	"ROLL": "Roll",
	"RUN_ATTACK": "Run_Attack",
	"SLIDE": "Slide",
	"WALL_CLIMB": "Wall_Climb",
	"WALL_HANG": "Wall_Hang"
}

# Node references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var label: Label = $Label
@onready var shooter: Shooter = $Shooter
@onready var health_bar: ProgressBar = $ProgressBar
@onready var stamina_bar: ProgressBar = $StaminaBar
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
@export var _invincibility_shader_material: ShaderMaterial

# Player state
var magic: float = STATS.MAX_MAGIC
var stamina: float = STATS.MAX_STAMINA
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

# Save Engine
@onready var save_engine: Node = get_node("/root/SaveEngine")

# Coyote Time Variables
var coyote_timer: float = 0.0
var has_coyote_time: bool = false

# Invincibility Variables
var invincibility_duration: float = 2.0  # Total duration of invincibility
var invincibility_timer: float = 0.0


func _ready() -> void:
	add_to_group("Player")
	super._ready()  # Call parent _ready to initialize health system
	types.player = self

	# Set collision layers and masks
	self.collision_layer = C_Layers.LAYER_PLAYER
	self.collision_mask = C_Layers.MASK_PLAYER

	# Also set the hitbox and hurtbox layers/masks
	if hitbox:
		hitbox.hitbox_owner = self
		hitbox.damage = 15.0
		hitbox.knockback_force = 200.0
		hitbox.hit_stun_duration = 0.2
		hitbox.collision_layer = C_Layers.LAYER_HITBOX
		hitbox.collision_mask = C_Layers.MASK_HITBOX
		hitbox.add_to_group("Hitbox")
		hitbox.active = true

	if hurtbox:
		hurtbox.hurtbox_owner = self
		hurtbox.collision_layer = C_Layers.LAYER_HURTBOX
		hurtbox.collision_mask = C_Layers.MASK_HURTBOX
		hurtbox.active = true

	set_jump_power(-450.0)

	# Initialize health system first
	health_system = HealthSystem.new()
	add_child(health_system)
	health_system._health_changed.connect(_on_health_changed)
	health_system._character_died.connect(_on_character_died)
	set_vigour(10)

	# Get initial health values
	current_health = health_system.get_health()
	max_health = health_system.get_max_health()
	health_percent = health_system.get_health_percentage()

	# Setup health bar
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.min_value = 0

	# Setup stamina bar
	stamina_bar.max_value = STATS.MAX_STAMINA
	stamina_bar.value = stamina
	stamina_bar.min_value = 0

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

	# Load saved game data if it exists
	if save_engine.load_game():
		_load_player_state(save_engine.get_save_data())


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
	_stamina_regen(delta)
	_update_player_state()
	_update_ui()
	_update_health_bar()
	_update_stamina_bar()

	# Handle invincibility effect
	if is_invincible:
		invincibility_timer += delta
		_invincibility_shader_material.set_shader_parameter("time_elapsed", invincibility_timer)
		
		if invincibility_timer >= invincibility_duration:
			_end_invincibility()


func _physics_process(delta: float) -> void:
	var was_on_floor = is_on_floor()

	if !is_on_floor():
		velocity.y += Types.GRAVITY_CONSTANT * delta
		# Only play fall animation when moving downward and not in a jump state
		if velocity.y > 0 and animated_sprite.animation != ANIMATIONS.FALL and !is_jump_active:
			animated_sprite.play(ANIMATIONS.FALL)

	# Handle coyote time
	if was_on_floor and !is_on_floor():
		coyote_timer = STATS.COYOTE_TIME
		has_coyote_time = true
	elif is_on_floor():
		has_coyote_time = false
		coyote_timer = 0.0
	elif coyote_timer > 0:
		coyote_timer -= delta
		if coyote_timer <= 0:
			has_coyote_time = false

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

	# Handle running stamina drain
	if _is_running():
		_use_stamina(STATS.RUN_STAMINA_DRAIN_RATE * delta)

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
		return MOVEMENT_SPEEDS.CROUCH
	elif _is_running():
		return MOVEMENT_SPEEDS.RUN
	return MOVEMENT_SPEEDS.WALK


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
			ANIMATIONS.ATTACK_COMBO,
			ANIMATIONS.JUMP_ATTACK,
			ANIMATIONS.RUN_ATTACK,
			ANIMATIONS.CROUCH_ATTACK
		]
	)


# Input Handling
func _handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("JUMP"):
		is_jump_held = true
		if is_on_floor() or has_coyote_time:
			_handle_jump()
		else:
			# Buffer the jump input
			InputBuffer.buffer_jump()
	elif event.is_action_released("JUMP"):
		is_jump_held = false

	# Handle dash input
	if event.is_action_pressed("DASH") and can_dash and not is_dashing:
		state_machine.dispatch(&"dash")

	# Handle roll input
	if event.is_action_pressed("ROLL") and is_on_floor():
		state_machine.dispatch(&"roll")

	# Handle slide input
	if event.is_action_pressed("SLIDE") and abs(velocity.x) > 0:
		state_machine.dispatch(&"slide")

	if event.is_action_released("ATTACK"):
		if is_on_floor():
			if abs(velocity.x) > 0:  # If moving on ground
				if _has_enough_stamina(STATS.RUN_ATTACK_STAMINA_COST):
					_use_stamina(STATS.RUN_ATTACK_STAMINA_COST)
					state_machine.dispatch(&"run_attack")
			else:
				if _has_enough_stamina(STATS.ATTACK_STAMINA_COST):
					_use_stamina(STATS.ATTACK_STAMINA_COST)
					state_machine.dispatch(&"attack")
	elif event.is_action_released("CROUCH"):
		state_machine.dispatch(&"crouch")
	elif event.is_action_released("SHOOT"):
		_shoot()

	# Wall interactions
	if is_on_wall():
		if event.is_action_pressed("GRAB"):
			state_machine.dispatch(&"wall_hang")
		elif event.is_action_pressed("UP") and state_machine.current_state.name == "wall_hang":
			state_machine.dispatch(&"wall_climb")

	# Health
	if event.is_action_released("HEALTH_DOWN"):
		take_damage(10.0)
	elif event.is_action_released("HEAL"):
		_heal(10.0)
	elif event.is_action_released("DIE"):
		take_damage(100.0)


func _handle_jump() -> void:
	if not _has_enough_stamina(STATS.JUMP_STAMINA_COST):
		return  # Don't jump if not enough stamina

	if is_on_floor() or has_coyote_time:
		_use_stamina(STATS.JUMP_STAMINA_COST)  # Consume stamina for jump
		velocity.y = jump_power
		is_jump_held = true
		is_jump_active = true
		has_coyote_time = false  # Consume coyote time
		coyote_timer = 0.0
		jump_timer.start()
		animated_sprite.play(ANIMATIONS.JUMP)
		InputBuffer.consume_jump_buffer()  # Consume any buffered jump


# Combat System
func _shoot() -> void:
	var dir = Vector2.LEFT if animated_sprite.flip_h else Vector2.RIGHT
	shooter.shoot(dir)


# Override parent's die function
func _die() -> void:
	state_machine.set_active(false)
	set_physics_process(false)

	# Play death animation
	animated_sprite.play(ANIMATIONS.DEATH)

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
	if is_invincible:
		return  # Skip damage if invincible
		
	current_health -= damage_amount
	current_health = clamp(current_health, 0.0, max_health)
	health_percent = (current_health / max_health) * 100.0

	if current_health <= 0:
		_die()
	else:
		# Play hurt animation and sound
		animated_sprite.play(ANIMATIONS.HURT)
		SoundManager.play_sound(Sound.oof, "SFX")

		# Enhanced screen shake with more impact
		camera.shake(12, 0.3, 0.85)  # Increased intensity and duration for more impact

		# Damage pause effect
		Engine.time_scale = 0.05  # Slow down time dramatically
		await get_tree().create_timer(0.3 * Engine.time_scale).timeout  # Account for time scale in pause duration
		Engine.time_scale = 1.0  # Return to normal time

		# Start invincibility
		_start_invincibility()

		# Update health bar
		health_bar.value = current_health


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
		"Class: %s\nFPS: %s\nHealth: %s/%s (%.1f%%)\nStamina: %.1f/%s\nAnimation: %s"
		% [
			"None",
			Engine.get_frames_per_second(),
			current_health,
			max_health,
			health_percent,
			stamina,
			STATS.MAX_STAMINA,
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


func _on_hit_landed(target_hurtbox: Node) -> void:
	if target_hurtbox.hurtbox_owner and target_hurtbox.hurtbox_owner.is_in_group("Enemy"):
		# Play hit effect or sound
		SoundManager.play_sound(Sound.hit, "SFX")
		# Apply lifesteal if enabled
		_apply_lifesteal(hitbox.damage)


func _on_hit_taken(attacker_hitbox: Node) -> void:
	if attacker_hitbox.hitbox_owner and attacker_hitbox.hitbox_owner.is_in_group("Enemy"):
		take_damage(attacker_hitbox.damage)


func _on_hurtbox_area_entered(_area: Area2D) -> void:
	pass  # Let hit_taken handle the damage


func _on_animation_changed() -> void:
	match animated_sprite.animation:
		ANIMATIONS.IDLE:
			animated_sprite.play(ANIMATIONS.IDLE)
		ANIMATIONS.RUN:
			animated_sprite.play(ANIMATIONS.RUN)
		ANIMATIONS.RUN_ATTACK:
			animated_sprite.play(ANIMATIONS.RUN_ATTACK)
		ANIMATIONS.CROUCH:
			animated_sprite.play(ANIMATIONS.CROUCH)
		ANIMATIONS.CROUCH_ATTACK:
			animated_sprite.play(ANIMATIONS.CROUCH_ATTACK)
		ANIMATIONS.CROUCH_RUN:
			animated_sprite.play(ANIMATIONS.CROUCH_RUN)
		ANIMATIONS.CROUCH_TRANSITION:
			animated_sprite.play(ANIMATIONS.CROUCH_TRANSITION)
		ANIMATIONS.JUMP:
			animated_sprite.play(ANIMATIONS.JUMP)
		ANIMATIONS.JUMP_ATTACK:
			animated_sprite.play(ANIMATIONS.JUMP_ATTACK)
		ANIMATIONS.ATTACK:
			animated_sprite.play(ANIMATIONS.ATTACK)
		ANIMATIONS.ATTACK_COMBO:
			animated_sprite.play(ANIMATIONS.ATTACK_COMBO)
		ANIMATIONS.DASH:
			animated_sprite.play(ANIMATIONS.DASH)
		ANIMATIONS.DEATH:
			animated_sprite.play(ANIMATIONS.DEATH)
		ANIMATIONS.FALL:
			animated_sprite.play(ANIMATIONS.FALL)
		ANIMATIONS.ROLL:
			animated_sprite.play(ANIMATIONS.ROLL)
		ANIMATIONS.SLIDE:
			animated_sprite.play(ANIMATIONS.SLIDE)
		ANIMATIONS.WALL_CLIMB:
			animated_sprite.play(ANIMATIONS.WALL_CLIMB)
		ANIMATIONS.WALL_HANG:
			animated_sprite.play(ANIMATIONS.WALL_HANG)


func _on_animation_finished() -> void:
	match animated_sprite.animation:
		ANIMATIONS.RUN:
			animated_sprite.play(ANIMATIONS.IDLE)
		ANIMATIONS.RUN_ATTACK:
			animated_sprite.play(ANIMATIONS.RUN)
		ANIMATIONS.CROUCH_ATTACK:
			animated_sprite.play(ANIMATIONS.CROUCH)
		ANIMATIONS.JUMP:
			animated_sprite.play(ANIMATIONS.IDLE)
		ANIMATIONS.JUMP_ATTACK:
			animated_sprite.play(ANIMATIONS.JUMP)
		ANIMATIONS.ATTACK:
			animated_sprite.play(ANIMATIONS.IDLE)
		ANIMATIONS.ATTACK_COMBO:
			animated_sprite.play(ANIMATIONS.IDLE)
		ANIMATIONS.DASH:
			animated_sprite.play(ANIMATIONS.IDLE)
		ANIMATIONS.DEATH:
			# Death animation stays on last frame
			pass
		ANIMATIONS.ROLL:
			animated_sprite.play(ANIMATIONS.IDLE)
		ANIMATIONS.SLIDE:
			animated_sprite.play(ANIMATIONS.SLIDE)
		ANIMATIONS.WALL_CLIMB:
			animated_sprite.play(ANIMATIONS.WALL_HANG)


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


# Stamina System
func _stamina_regen(delta: float) -> void:
	if not is_attacking and not _is_running():
		stamina = min(stamina + STATS.STAMINA_REGEN_RATE * delta, STATS.MAX_STAMINA)


func _is_running() -> bool:
	return abs(velocity.x) > 0 and not is_crouching


func _update_stamina_bar() -> void:
	stamina_bar.value = stamina


func _has_enough_stamina(cost: float) -> bool:
	return stamina >= cost


func _use_stamina(amount: float) -> void:
	stamina = max(0.0, stamina - amount)


# Save System
func _load_player_state(save_data: SaveData) -> void:
	# Only load position if we don't have a last bonfire position
	if save_data.last_bonfire_position == Vector2.ZERO:
		position = save_data.player_position
	else:
		position = save_data.last_bonfire_position

	current_health = save_data.current_health
	stamina = save_data.current_stamina
	magic = save_data.current_magic

	# Update UI
	_update_health_bar()
	_update_stamina_bar()
	_update_ui()


func save_player_state() -> void:
	save_engine.update_save_data(self)
	save_engine.save_game()


func respawn_at_bonfire() -> void:
	var bonfire_pos = save_engine.get_last_bonfire_position()
	if bonfire_pos != Vector2.ZERO:
		position = bonfire_pos
		_heal(max_health)  # Full heal on respawn
		stamina = STATS.MAX_STAMINA  # Full stamina on respawn
		magic = STATS.MAX_MAGIC  # Full magic on respawn


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


# Add these methods to the player class
func get_max_health() -> float:
	return max_health

func get_max_stamina() -> float:
	return STATS.MAX_STAMINA

func restore_stamina(amount: float) -> void:
	stamina = min(stamina + amount, STATS.MAX_STAMINA)
	_update_stamina_bar()

func heal(amount: float) -> void:
	_heal(amount)  # Use existing heal method

func _start_invincibility() -> void:
	is_invincible = true
	invincibility_timer = 0.0
	animated_sprite.material = _invincibility_shader_material
	_invincibility_shader_material.set_shader_parameter("time_elapsed", 0.0)
	_invincibility_shader_material.set_shader_parameter("base_visible_duration", 0.2)
	_invincibility_shader_material.set_shader_parameter("base_invisible_duration", 0.1)
	_invincibility_shader_material.set_shader_parameter("duration_increase_rate", 0.001)
	hurtbox.start_invincibility(invincibility_duration)

func _end_invincibility() -> void:
	is_invincible = false
	invincibility_timer = 0.0
	animated_sprite.material = _shader_material
	hurtbox.end_invincibility()
