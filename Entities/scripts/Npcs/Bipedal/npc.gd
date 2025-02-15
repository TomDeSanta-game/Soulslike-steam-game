extends NpcBase

@export_group("NPC Animation")
@export var idle_animation: StringName = &"Stop"
@export var run_animation: StringName = &"Run"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_timer: Timer = $Timer


func _ready() -> void:
	super._ready()
	_setup_console_commands()
	_setup_timer()


func _process(_delta: float) -> void:
	_update_animation()


func _setup_timer() -> void:
	state_timer.timeout.connect(_on_timer_timeout)
	state_timer.start()


func _update_animation() -> void:
	if (
		current_state == Types.CharacterState.IDLE
		or current_state == Types.CharacterState.NEW_DIRECTION
	):
		animated_sprite.play(idle_animation)
	elif current_state == Types.CharacterState.MOVE and not is_chatting:
		animated_sprite.play(run_animation)


func _setup_console_commands() -> void:
	LimboConsole.register_command(change_state)


func change_state(new_state_str: String) -> void:
	match new_state_str.to_upper():
		"IDLE":
			current_state = Types.CharacterState.IDLE
		"NEW_DIR":
			current_state = Types.CharacterState.NEW_DIRECTION
		"MOVE":
			current_state = Types.CharacterState.MOVE
		_:
			push_warning("Invalid state: %s" % new_state_str)
			return

	print("Current State: ", Types.CharacterState.keys()[current_state])


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if is_roaming and not is_chatting:
		match current_state:
			Types.CharacterState.IDLE:
				velocity.x = 0
			Types.CharacterState.NEW_DIRECTION:
				movement_direction = choose([Vector2.RIGHT, Vector2.LEFT])
			Types.CharacterState.MOVE:
				_handle_movement(delta)

	move_and_slide()


func _handle_movement(delta: float) -> void:
	if not is_chatting:
		position += movement_direction * base_run_speed * delta


func choose(array: Array) -> Variant:
	array.shuffle()
	return array.front()


func die() -> void:
	queue_free()


func flash_damage_effect(sprite: AnimatedSprite2D) -> void:
	var mat := sprite.material
	if mat is ShaderMaterial:
		mat.set_shader_parameter("damage_effect", 1.0)
		await get_tree().create_timer(0.1).timeout
		mat.set_shader_parameter("damage_effect", 0.0)


func _on_chat_box_area_body_entered(body: CharacterBody2D) -> void:
	if body.is_in_group("Player"):
		is_chatting = true
		chat_started.emit(body)


func _on_chat_box_area_body_exited(body: CharacterBody2D) -> void:
	if body.is_in_group("Player"):
		is_chatting = false
		chat_ended.emit(body)


func _on_timer_timeout() -> void:
	state_timer.wait_time = choose([0.5, 1.0, 1.5])
	current_state = choose(
		[Types.CharacterState.IDLE, Types.CharacterState.NEW_DIRECTION, Types.CharacterState.MOVE]
	)
