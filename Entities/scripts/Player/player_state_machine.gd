extends LimboHSM
class_name PlayerStateMachine

# Player reference
var player: CharacterBody2D

# State configurations
var states: Dictionary = {}

# Constants for state names
const STATE_IDLE: String = "idle"
const STATE_RUN: String = "run"
const STATE_RUN_ATTACK: String = "run_attack"
const STATE_JUMP: String = "jump"
const STATE_FALL: String = "fall"
const STATE_ATTACK: String = "attack"
const STATE_CROUCH: String = "crouch"
const STATE_HURT: String = "hurt"
const STATE_DASH: String = "dash"
const STATE_ROLL: String = "roll"
const STATE_SLIDE: String = "slide"
const STATE_WALL_HANG: String = "wall_hang"

# Add to the top of the file
# signal attack_started
# signal attack_ended


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
		STATE_FALL: _create_state(STATE_FALL, fall_start, fall_update),
		STATE_ATTACK: _create_state(STATE_ATTACK, attack_start, attack_update),
		STATE_CROUCH: _create_state(STATE_CROUCH, crouch_start, crouch_update),
		STATE_HURT: _create_state(STATE_HURT, hurt_start, hurt_update),
		STATE_DASH: _create_state(STATE_DASH, dash_start, dash_update),
		STATE_ROLL: _create_state(STATE_ROLL, roll_start, roll_update),
		STATE_SLIDE: _create_state(STATE_SLIDE, slide_start, slide_update),
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
		[states[STATE_IDLE], states[STATE_FALL], &"fall"],
		[states[STATE_IDLE], states[STATE_CROUCH], &"crouch"],
		[states[STATE_IDLE], states[STATE_ROLL], &"roll"],
		[states[STATE_IDLE], states[STATE_DASH], &"dash"],
		[ANYSTATE, states[STATE_IDLE], &"state_ended"],
		[states[STATE_RUN], states[STATE_JUMP], &"jump"],
		[states[STATE_RUN], states[STATE_FALL], &"fall"],
		[states[STATE_RUN], states[STATE_ATTACK], &"attack"],
		[states[STATE_RUN], states[STATE_CROUCH], &"crouch"],
		[states[STATE_RUN], states[STATE_RUN_ATTACK], &"run_attack"],
		[states[STATE_RUN], states[STATE_SLIDE], &"slide"],
		[states[STATE_JUMP], states[STATE_FALL], &"fall"],
		[states[STATE_FALL], states[STATE_IDLE], &"state_ended"],
		[states[STATE_RUN_ATTACK], states[STATE_RUN], &"state_ended"],
		[states[STATE_CROUCH], states[STATE_IDLE], &"state_ended"],
		[states[STATE_CROUCH], states[STATE_ATTACK], &"attack"],
		[states[STATE_ATTACK], states[STATE_CROUCH], &"crouch"],
		[ANYSTATE, states[STATE_HURT], &"hurt"],
		[ANYSTATE, states[STATE_WALL_HANG], &"wall_hang"],
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
	if InputBuffer.has_buffered_jump():
		player._handle_jump()
		dispatch(&"jump")
	elif Input.is_action_pressed("CROUCH"):
		dispatch(&"crouch")
	elif player.velocity.x != 0:
		dispatch(&"run")
	elif not player.is_on_floor() and player.velocity.y > 0:
		dispatch(&"fall")


func run_start() -> void:
	player.animated_sprite.play(player.ANIMATIONS.RUN)
	player.current_speed = player.base_run_speed


func run_update(_delta: float) -> void:
	if player.velocity.x == 0:
		dispatch(&"state_ended")
	elif not player.is_on_floor() and player.velocity.y > 0:
		dispatch(&"fall")


func run_attack_start() -> void:
	player.animated_sprite.play(player.ANIMATIONS.RUN_ATTACK)
	SoundManager.play_sound(Sound.run_attack, "SFX")
	player.attack_timer.start()


func run_attack_update(_delta: float) -> void:
	if player.velocity.x == 0:
		dispatch(&"state_ended")  # Return to idle if stopped moving


func jump_start() -> void:
	player.animated_sprite.play(player.ANIMATIONS.JUMP)


func jump_update(_delta: float) -> void:
	if player.is_on_floor():
		player.is_jump_active = false
		player.jump_timer.stop()
		if abs(player.velocity.x) > 0:
			dispatch(&"run")
		else:
			dispatch(&"state_ended")
	elif player.velocity.y > 0 and not player.is_jump_active:  # Only transition to fall if we're not actively jumping
		dispatch(&"fall")
	
	# Always play jump animation while in jump state, regardless of horizontal movement
	player.animated_sprite.play(player.ANIMATIONS.JUMP)


func attack_start() -> void:
	player.animated_sprite.play(player.ANIMATIONS.ATTACK)
	SoundManager.play_sound(Sound._attack, "SFX")
	player.attack_timer.start()
	SignalBus.attack_started.emit(player)


func attack_update(_delta: float) -> void:
	if player.attack_timer.is_stopped():
		SignalBus.attack_ended.emit(player)
		# If we were crouching before the attack, return to crouch
		if Input.is_action_pressed("CROUCH"):
			dispatch(&"crouch")
		else:
			dispatch(&"state_ended")


func crouch_start() -> void:
	player.animated_sprite.play(player.ANIMATIONS.CROUCH)
	player.is_crouching = true
	player.current_speed = player.base_crouch_speed


func crouch_update(_delta: float) -> void:
	if Input.is_action_just_pressed("ATTACK"):
		# Only allow attack if we have enough stamina
		if player._has_enough_stamina(player.STATS.ATTACK_STAMINA_COST):
			player._use_stamina(player.STATS.ATTACK_STAMINA_COST)
			dispatch(&"attack")
	elif !Input.is_action_pressed("CROUCH"):
		player.is_crouching = false
		dispatch(&"state_ended")
	else:
		# Always use the crouch animation, regardless of movement
		player.animated_sprite.play(player.ANIMATIONS.CROUCH)


func hurt_start() -> void:
	player.animated_sprite.play(player.ANIMATIONS.HURT)
	player._reset_acceleration()
	player.hurt_timer.start()


func hurt_update(_delta: float) -> void:
	pass


func dash_start() -> void:
	# Check if player has enough stamina
	if not player._has_enough_stamina(50.0):
		dispatch(&"state_ended")
		return
		
	player._use_stamina(50.0)  # Use 50 stamina for dash
	player.animated_sprite.play(player.ANIMATIONS.DASH)
	
	# Apply immediate position change for instant dash start
	var dash_direction = -1.0 if player.animated_sprite.flip_h else 1.0
	player.position.x += 30 * dash_direction  # Add immediate position change
	
	player._start_dash()
	# Disable gravity during dash
	player.set_gravity_enabled(false)


func dash_update(_delta: float) -> void:
	if not player.is_dashing:
		# Re-enable gravity after dash
		player.set_gravity_enabled(true)
		dispatch(&"state_ended")
	else:
		# Keep playing dash animation
		if not player.animated_sprite.is_playing():
			player.animated_sprite.play(player.ANIMATIONS.DASH)


func roll_start() -> void:
	# Check if player has enough stamina
	if not player._has_enough_stamina(10.0):
		dispatch(&"state_ended")
		return
		
	player._use_stamina(10.0)  # Use 10 stamina for roll
	player.animated_sprite.play(player.ANIMATIONS.ROLL)
	
	# Calculate roll direction
	var roll_direction = -1.0 if player.animated_sprite.flip_h else 1.0
	
	# Create tween for smooth position change
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "position:x", player.position.x + (10 * roll_direction), 0.15)
	
	# Disable player input during roll
	player.set_physics_process(false)
	
	# Start roll timer
	var roll_timer = get_tree().create_timer(0.5)  # Duration of roll animation
	roll_timer.timeout.connect(func():
		player.set_physics_process(true)
		dispatch(&"state_ended")
	)


func roll_update(_delta: float) -> void:
	# Keep playing roll animation until it's done
	if not player.animated_sprite.is_playing():
		player.animated_sprite.play(player.ANIMATIONS.ROLL)


func slide_start() -> void:
	# Check if player has enough stamina to slide
	if player.stamina >= 40.0:
		player.animated_sprite.play(player.ANIMATIONS.SLIDE)
		# Add slide movement boost
		var slide_direction = -1.0 if player.animated_sprite.flip_h else 1.0
		player.velocity.x = slide_direction * player.base_run_speed * 1.5  # 1.5x speed boost during slide
		# Consume stamina
		player._use_stamina(40.0)
	else:
		# If not enough stamina, go back to idle
		dispatch(&"state_ended")


func slide_update(_delta: float) -> void:
	# Gradually slow down during slide
	player.velocity.x = move_toward(player.velocity.x, 0, player.base_run_speed * 0.05)
	
	# End slide if nearly stopped or animation finished
	if abs(player.velocity.x) < 50 or not player.animated_sprite.is_playing():
		dispatch(&"state_ended")


func wall_hang_start() -> void:
	player.animated_sprite.play(player.ANIMATIONS.WALL_HANG)
	player.velocity.x = 0  # Stop horizontal movement
	player.velocity.y = 0  # Stop vertical movement initially


func wall_hang_update(delta: float) -> void:
	if not player.is_on_wall():
		player._end_grab()
		dispatch(&"fall")
		return

	if Input.is_action_just_pressed("JUMP"):
		player._end_grab()
		# Wall jump
		var jump_direction = -1 if player.animated_sprite.flip_h else 1
		player.velocity.x = jump_direction * 300.0  # Horizontal jump force
		player.velocity.y = player.jump_power  # Use regular jump power
		dispatch(&"jump")
	elif not Input.is_action_pressed("GRAB"):
		player._end_grab()
		dispatch(&"fall")
	else:
		player._update_wall_climbing(delta)


func fall_start() -> void:
	player.animated_sprite.play(player.ANIMATIONS.FALL)


func fall_update(_delta: float) -> void:
	if player.is_on_floor():
		if InputBuffer.has_buffered_jump():
			player._handle_jump()
			dispatch(&"jump")
		elif abs(player.velocity.x) > 0:
			dispatch(&"run")
		else:
			dispatch(&"state_ended")
		return  # Exit early to prevent playing fall animation after landing
	
	# Always play fall animation while in fall state, regardless of horizontal movement
	player.animated_sprite.play(player.ANIMATIONS.FALL)
