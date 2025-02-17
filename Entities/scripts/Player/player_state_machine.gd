extends LimboHSM
class_name PlayerStateMachine

# Player reference
var player: CharacterBody2D

# State configurations
var states: Dictionary = {}

# Track previous flip state
var was_flipped: bool = false
var is_turning: bool = false

# Constants for state names
const STATE_IDLE: String = "idle"
const STATE_RUN: String = "run"
const STATE_RUN_ATTACK: String = "run_attack"
const STATE_JUMP: String = "jump"
const STATE_ATTACK: String = "attack"
const STATE_CROUCH: String = "crouch"
const STATE_CROUCH_ATTACK: String = "crouch_attack"
const STATE_HURT: String = "hurt"
const STATE_DASH: String = "dash"
const STATE_ROLL: String = "roll"
const STATE_SLIDE: String = "slide"
const STATE_WALL_CLIMB: String = "wall_climb"
const STATE_WALL_HANG: String = "wall_hang"

# Add to the top of the file
signal attack_started
signal attack_ended


# Initialize the state machine
func init(player_node: CharacterBody2D) -> void:
	player = player_node

	agent = player

	# Create states
	states = {
		STATE_IDLE: _create_state(STATE_IDLE, idle_start, idle_update),
		STATE_RUN: _create_state(STATE_RUN, run_start, run_update),
		STATE_RUN_ATTACK: _create_state(STATE_RUN_ATTACK, run_attack_start, run_attack_update),
		STATE_JUMP: _create_state(STATE_JUMP, jump_start, jump_update),
		STATE_ATTACK: _create_state(STATE_ATTACK, attack_start, attack_update),
		STATE_CROUCH: _create_state(STATE_CROUCH, crouch_start, crouch_update),
		STATE_CROUCH_ATTACK:
		_create_state(STATE_CROUCH_ATTACK, crouch_attack_start, crouch_attack_update),
		STATE_HURT: _create_state(STATE_HURT, hurt_start, hurt_update),
		STATE_DASH: _create_state(STATE_DASH, dash_start, dash_update),
		STATE_ROLL: _create_state(STATE_ROLL, roll_start, roll_update),
		STATE_SLIDE: _create_state(STATE_SLIDE, slide_start, slide_update),
		STATE_WALL_CLIMB: _create_state(STATE_WALL_CLIMB, wall_climb_start, wall_climb_update),
		STATE_WALL_HANG: _create_state(STATE_WALL_HANG, wall_hang_start, wall_hang_update),
	}

	# Add states to the state machine
	for state in states.values():
		add_child(state)

	# Set initial state
	initial_state = states[STATE_IDLE]

	set_active(true)

	# Setup transitions
	_setup_transitions()


# Create a state
func _create_state(n: String, e: Callable, u: Callable) -> LimboState:
	return LimboState.new().named(n).call_on_enter(e).call_on_update(u)


# Setup state transitions
func _setup_transitions() -> void:
	var transitions = [
		[states[STATE_IDLE], states[STATE_RUN], &"run"],
		[states[STATE_IDLE], states[STATE_ATTACK], &"attack"],
		[states[STATE_IDLE], states[STATE_JUMP], &"jump"],
		[states[STATE_IDLE], states[STATE_CROUCH], &"crouch"],
		[states[STATE_IDLE], states[STATE_ROLL], &"roll"],
		[states[STATE_IDLE], states[STATE_DASH], &"dash"],
		[ANYSTATE, states[STATE_IDLE], &"state_ended"],
		[states[STATE_RUN], states[STATE_JUMP], &"jump"],
		[states[STATE_RUN], states[STATE_ATTACK], &"attack"],
		[states[STATE_RUN], states[STATE_CROUCH], &"crouch"],
		[states[STATE_RUN], states[STATE_RUN_ATTACK], &"run_attack"],
		[states[STATE_RUN], states[STATE_SLIDE], &"slide"],
		[states[STATE_RUN_ATTACK], states[STATE_RUN], &"state_ended"],
		[states[STATE_CROUCH], states[STATE_CROUCH_ATTACK], &"crouch_attack"],
		[states[STATE_CROUCH], states[STATE_IDLE], &"state_ended"],
		[states[STATE_CROUCH_ATTACK], states[STATE_IDLE], &"state_ended"],
		[states[STATE_CROUCH_ATTACK], states[STATE_CROUCH], &"crouch"],
		[ANYSTATE, states[STATE_HURT], &"hurt"],
		[ANYSTATE, states[STATE_WALL_HANG], &"wall_hang"],
		[states[STATE_WALL_HANG], states[STATE_WALL_CLIMB], &"wall_climb"],
		[states[STATE_WALL_CLIMB], states[STATE_WALL_HANG], &"wall_hang"],
		[states[STATE_SLIDE], states[STATE_IDLE], &"state_ended"],
		[states[STATE_ROLL], states[STATE_IDLE], &"state_ended"],
		[states[STATE_DASH], states[STATE_IDLE], &"state_ended"],
	]

	for transition in transitions:
		add_transition(transition[0], transition[1], transition[2])


# State implementations
func idle_start() -> void:
	player.animated_sprite.play(player.ANIMATIONS.IDLE)
	player._reset_acceleration()
	player.current_speed = 0.0


func idle_update(_delta: float) -> void:
	if Input.is_action_pressed("CROUCH"):
		dispatch(&"crouch")
	elif player.velocity.x != 0:
		dispatch(&"run")
	elif player.velocity.y != 0:
		dispatch(&"jump")


func run_start() -> void:
	player.animated_sprite.play(player.ANIMATIONS.RUN)
	player.current_speed = player.base_run_speed


func run_update(_delta: float) -> void:
	if player.velocity.x == 0:
		dispatch(&"state_ended")
	elif player.velocity.y != 0:
		dispatch(&"jump")
	else:
		# Check for direction change
		var moving_left = player.velocity.x < 0
		var facing_left = player.animated_sprite.flip_h

		if moving_left != facing_left and not is_turning:
			# Start turn around animation without flipping
			player.animated_sprite.play(player.ANIMATIONS.TURN_AROUND)
			is_turning = true
			# Store the direction we want to end up facing
			was_flipped = moving_left


func run_attack_start() -> void:
	player.animated_sprite.play(player.ANIMATIONS.RUN_ATTACK)
	SoundManager.play_sound(Sound.run_attack, "SFX")
	player.attack_timer.start()


func run_attack_update(_delta: float) -> void:
	if player.velocity.x == 0:
		dispatch(&"state_ended")  # Return to idle if stopped moving


func jump_start() -> void:
	player.animated_sprite.play(player.ANIMATIONS.JUMP)
	player.velocity.y = player.jump_power  # Set the initial jump velocity


func jump_update(_delta: float) -> void:
	if player.is_on_floor():
		player.is_jump_active = false
		player.jump_timer.stop()
		if abs(player.velocity.x) > 0:
			dispatch(&"run")  # Transition to RUN if moving horizontally
		else:
			dispatch(&"state_ended")  # Transition to IDLE if not moving


func attack_start() -> void:
	player.animated_sprite.play(player.ANIMATIONS.ATTACK)
	SoundManager.play_sound(Sound._attack, "SFX")
	player.attack_timer.start()
	emit_signal("attack_started")


func attack_update(_delta: float) -> void:
	if player.attack_timer.is_stopped():
		emit_signal("attack_ended")
		dispatch(&"state_ended")


func crouch_start() -> void:
	# Play transition animation first
	player.animated_sprite.play(player.ANIMATIONS.CROUCH_TRANSITION)
	player.animated_sprite.animation_finished.connect(
		_on_crouch_transition_finished, CONNECT_ONE_SHOT
	)
	player.is_crouching = true
	player.current_speed = player.base_crouch_speed


func crouch_update(_delta: float) -> void:
	if Input.is_action_just_pressed("ATTACK"):
		dispatch(&"crouch_attack")
	elif not Input.is_action_pressed("CROUCH"):
		# Play transition animation in reverse when uncrouch
		player.animated_sprite.play(player.ANIMATIONS.CROUCH_TRANSITION)
		if !player.animated_sprite.animation_finished.is_connected(
			_on_uncrouch_transition_finished
		):
			player.animated_sprite.animation_finished.connect(
				_on_uncrouch_transition_finished, CONNECT_ONE_SHOT
			)
	else:
		# Handle crouch movement
		if abs(player.velocity.x) > 0:
			player.animated_sprite.play(player.ANIMATIONS.CROUCH_RUN)
		elif player.animated_sprite.animation != player.ANIMATIONS.CROUCH_TRANSITION:
			player.animated_sprite.play(player.ANIMATIONS.CROUCH)


func _on_crouch_transition_finished() -> void:
	if player.is_crouching:
		player.animated_sprite.play(player.ANIMATIONS.CROUCH)


func _on_uncrouch_transition_finished() -> void:
	player.is_crouching = false
	dispatch(&"state_ended")


func crouch_attack_start() -> void:
	player.animated_sprite.play(player.ANIMATIONS.CROUCH_ATTACK)
	player.crouch_attack_timer.start()
	emit_signal("attack_started")


func crouch_attack_update(_delta: float) -> void:
	# Only check for state changes after both animation and timer are done
	if player.crouch_attack_timer.is_stopped() and not player.animated_sprite.is_playing():
		emit_signal("attack_ended")
		# If still holding crouch, go back to crouch state
		if Input.is_action_pressed("CROUCH"):
			dispatch(&"crouch")
		# If not holding crouch, go to idle
		else:
			player.is_crouching = false
			dispatch(&"state_ended")


func hurt_start() -> void:
	player.animated_sprite.play(player.ANIMATIONS.HURT)
	player._reset_acceleration()
	player.hurt_timer.start()


func hurt_update(_delta: float) -> void:
	pass


func dash_start() -> void:
	player.animated_sprite.play(player.ANIMATIONS.DASH)
	player._start_dash()


func dash_update(_delta: float) -> void:
	if not player.is_dashing:
		dispatch(&"state_ended")


func roll_start() -> void:
	player.animated_sprite.play(player.ANIMATIONS.ROLL)
	# Add roll movement
	var roll_direction = -1.0 if player.animated_sprite.flip_h else 1.0
	player.position.x += 10 * roll_direction


func roll_update(_delta: float) -> void:
	if not player.animated_sprite.is_playing():
		dispatch(&"state_ended")


func slide_start() -> void:
	player.animated_sprite.play(player.ANIMATIONS.SLIDE_START)


func slide_update(_delta: float) -> void:
	if not player.animated_sprite.is_playing():
		dispatch(&"state_ended")


func wall_climb_start() -> void:
	player.animated_sprite.play(player.ANIMATIONS.WALL_CLIMB)


func wall_climb_update(_delta: float) -> void:
	if not player.is_on_wall():
		dispatch(&"state_ended")


func wall_hang_start() -> void:
	player.animated_sprite.play(player.ANIMATIONS.WALL_HANG)


func wall_hang_update(_delta: float) -> void:
	if not player.is_on_wall():
		dispatch(&"state_ended")
	elif Input.is_action_just_pressed("UP"):
		dispatch(&"wall_climb")


# Add this new function to handle turn completion
func _on_turn_around_finished() -> void:
	is_turning = false
	# Apply the stored flip state after animation completes
	player.animated_sprite.flip_h = was_flipped
	if abs(player.velocity.x) > 0:
		player.animated_sprite.play(player.ANIMATIONS.RUN)
	else:
		player.animated_sprite.play(player.ANIMATIONS.IDLE)
