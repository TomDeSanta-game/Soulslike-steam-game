class_name GhostPlayer extends CharacterBase

# Constants and Configuration
const STATS: Dictionary = {
	"MAX_MAGIC": 100.0,
	"MAGIC_COST": 10.0,
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
@onready var shooter: Shooter = $Shooter
@onready var camera: Camera2D = $Camera2D

# Types
@onready var types: Types = Types.new()

# Timers
@onready var hurt_timer: Timer = $HurtTimer
@onready var attack_timer: Timer = $AttackTimer
@onready var crouch_attack_timer: Timer = $CrouchAttackTimer
@onready var death_timer: Timer = $DeathTimer

# Player Group
@export_group("Shaders")
@export var _ghost_shader_material: ShaderMaterial

# Player state
var magic: float = STATS.MAX_MAGIC
var main_sm: LimboHSM
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

# Damage Shader
var effect_duration: float = 1.66666666667  # Duration of the effect
var effect_timer: float = 0.0  # Timer for the effect


func _ready() -> void:
	super._ready()  # Call parent _ready to initialize health system
	types.player = self

	animated_sprite.material = _ghost_shader_material

	base_run_speed = MOVEMENT_SPEEDS.RUN
	base_crouch_speed = MOVEMENT_SPEEDS.CROUCH

	_setup_commands()
	_init_state_machine()
	_connect_signals()


func _process(_delta: float) -> void:
	_update_player_state()


func _physics_process(delta: float) -> void:
	_handle_movement()


func _setup_commands() -> void:
	LimboConsole.register_command(_die)
	LimboConsole.register_command(_respawn)


func _unhandled_input(event: InputEvent) -> void:
	_handle_input(event)


# Movement System
func _handle_movement() -> void:
	direction = Input.get_axis("left", "right")

	var speed = _get_current_speed()

	if current_state == Types.CharacterState.IDLE or current_state == Types.CharacterState.MOVE:
		if direction != 0:
			velocity.x = direction * speed
		else:
			velocity.x = 0

	_update_sprite_direction()
	_update_movement_state()


func _get_current_speed() -> float:
	# Return different speeds based on current state
	if is_crouching:
		return base_crouch_speed
	return base_run_speed


func _update_movement_state() -> void:
	if direction != 0:
		current_state = Types.CharacterState.MOVE
	elif velocity.x != 0:
		current_state = Types.CharacterState.NEW_DIRECTION
	else:
		current_state = Types.CharacterState.IDLE


func _update_sprite_direction() -> void:
	if direction != 0:
		animated_sprite.flip_h = direction < 0


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
	if event.is_action_released("attack"):
		main_sm.dispatch(&"attack")
	elif event.is_action_released("jump") and is_on_floor():
		_handle_jump()
	elif event.is_action_released("crouch"):
		main_sm.dispatch(&"crouch")
	elif event.is_action_released("shoot"):
		_shoot()


func _handle_jump() -> void:
	velocity.y = jump_power


# Combat System
func _shoot() -> void:
	var dir = Vector2.LEFT if animated_sprite.flip_h else Vector2.RIGHT
	shooter.shoot(dir)


# Override parent's die function
func _die() -> void:
	# super.die()  # Call parent implementation first
	# main_sm.set_active(false)

	# Screen Shake
	camera.shake(10, 0.5, 0.9)

	# Death Sound
	SoundManager.play_sound(Sound.death, "SFX")

	# # Start the fade effect
	# is_fading = true
	# fade_timer = 0.0

	$GameOverLabel.show()
	hide()


func _respawn() -> void:
	# main_sm.set_active(true)
	# # Reset player state
	# is_fading = false
	# fade_timer = 0.0

	$GameOverLabel.hide()

	# Sound
	SoundManager.play_sound(Sound.respawn, "SFX")

	# # Reset player position or other state as needed
	# position.x = 0
	# position.y = 0

	# Dispatch Idle
	main_sm.dispatch(&"state_ended")

	set_physics_process(true)
	show()


# Magic System
func _handle_magic(healing_amount: float) -> void:
	if magic >= STATS.MAGIC_COST:
		health_system.heal(healing_amount)
		magic = max(0, magic - STATS.MAGIC_COST)


# State Machine Implementation
func _init_state_machine() -> void:
	main_sm = LimboHSM.new()
	add_child(main_sm)

	var states = _create_states()
	_add_states(states)
	_setup_transitions(states)

	main_sm.initialize(self)
	main_sm.set_active(true)


func _create_states() -> Dictionary:
	return {
		"idle": _create_state("idle", idle_start, idle_update),
		"run": _create_state("run", run_start, run_update),
		"jump": _create_state("jump", jump_start, jump_update),
		"attack": _create_state("attack", attack_start, attack_update),
		"crouch": _create_state("crouch", crouch_start, crouch_update),
		"crouch_attack": _create_state("crouch_attack", crouch_attack_start, crouch_attack_update),
		"hurt": _create_state("hurt", hurt_start, hurt_update),
	}


func _create_state(n: String, enter_func: Callable, update_func: Callable) -> LimboState:
	return LimboState.new().named(n).call_on_enter(enter_func).call_on_update(update_func)


func _add_states(states: Dictionary) -> void:
	for state in states.values():
		main_sm.add_child(state)
	main_sm.initial_state = states["idle"]


func _setup_transitions(states: Dictionary) -> void:
	var transitions = [
		[states["idle"], states["run"], &"run"],
		[states["idle"], states["attack"], &"attack"],
		[states["idle"], states["jump"], &"jump"],
		[states["idle"], states["crouch"], &"crouch"],
		[main_sm.ANYSTATE, states["idle"], &"state_ended"],
		[states["run"], states["jump"], &"jump"],
		[states["run"], states["attack"], &"attack"],
		[states["run"], states["crouch"], &"crouch"],
		[states["crouch"], states["crouch_attack"], &"crouch_attack"],
		[states["crouch"], states["crouch"], &"crouch"],
		[states["crouch_attack"], states["crouch"], &"crouch"],
		[main_sm.ANYSTATE, states["hurt"], &"hurt"],
	]

	for transition in transitions:
		main_sm.add_transition(transition[0], transition[1], transition[2])


func _connect_signals() -> void:
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	hurt_timer.timeout.connect(_on_hurt_timer_timeout)
	crouch_attack_timer.timeout.connect(_on_crouch_attack_timer_timeout)


# State Implementations
func idle_start() -> void:
	animated_sprite.play(ANIMATIONS.IDLE)
	current_speed = 0.0


func idle_update(_delta: float) -> void:
	if velocity.x != 0:
		main_sm.dispatch(&"run")
	if velocity.y != 0:
		main_sm.dispatch(&"jump")


func run_start() -> void:
	animated_sprite.play(ANIMATIONS.RUN)
	current_speed = base_run_speed


func run_update(_delta: float) -> void:
	if velocity.x == 0:
		main_sm.dispatch(&"state_ended")
	if velocity.y != 0:
		main_sm.dispatch(&"jump")


func jump_start() -> void:
	animated_sprite.play(ANIMATIONS.JUMP)


func jump_update(_delta: float) -> void:
	if velocity.y == 0 and is_on_floor():
		main_sm.dispatch(&"state_ended")  # End jump state if landed


func attack_start() -> void:
	animated_sprite.play(ANIMATIONS.ATTACK)
	attack_timer.start()


func attack_update(_delta: float) -> void:
	pass


func crouch_start() -> void:
	animated_sprite.play(ANIMATIONS.CROUCH)
	is_crouching = true
	current_speed = base_crouch_speed


func crouch_update(_delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		is_crouching = false
		main_sm.dispatch(&"crouch_attack")
	if Input.is_action_just_pressed("up"):
		is_crouching = false
		main_sm.dispatch(&"state_ended")


func crouch_attack_start() -> void:
	animated_sprite.play(ANIMATIONS.CROUCH_ATTACK)
	crouch_attack_timer.start()


func crouch_attack_update(_delta: float) -> void:
	pass


func hurt_start() -> void:
	animated_sprite.play(ANIMATIONS.HURT)
	hurt_timer.start()


func hurt_update(_delta: float) -> void:
	pass


# Signal Callbacks
func _on_attack_timer_timeout() -> void:
	main_sm.dispatch(&"state_ended")


func _on_crouch_attack_timer_timeout() -> void:
	main_sm.dispatch(&"crouch")


func _on_hurt_timer_timeout() -> void:
	main_sm.dispatch(&"state_ended")
