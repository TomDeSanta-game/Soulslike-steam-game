class_name NpcBase extends CharacterBase

@export_group("NPC Behavior")
@export var is_roaming: bool = true
@export var chat_enabled: bool = true
@export var roam_distance: float = 100.0

var current_state: Types.CharacterState = Types.CharacterState.IDLE
var movement_direction: Vector2 = Vector2.RIGHT
var start_position: Vector2
var is_chatting: bool = false

@onready var timer: Timer = $StateTimer
@onready var chat_area: Area2D = $ChatBoxArea

var player_ref = null


func _ready() -> void:
	super._ready()

	player_ref = get_tree().get_nodes_in_group("Player").front()

	start_position = global_position
	_setup_state_timer()


func _physics_process(delta: float) -> void:
	if is_roaming and not is_chatting:
		_handle_roaming_behavior(delta)


func _handle_roaming_behavior(delta: float) -> void:
	match current_state:
		Types.CharacterState.IDLE:
			velocity.x = 0
		Types.CharacterState.NEW_DIRECTION:
			_choose_new_direction()
		Types.CharacterState.MOVE:
			_move(delta)

	if abs(global_position.x - start_position.x) > roam_distance:
		movement_direction.x *= -1
		global_position.x = start_position.x + (roam_distance * sign(movement_direction.x))


func _choose_new_direction() -> void:
	movement_direction = Vector2.RIGHT if randf() > 0.5 else Vector2.LEFT


func _move(_delta: float) -> void:
	if not is_chatting:
		velocity.x = movement_direction.x * base_run_speed


func _setup_state_timer() -> void:
	timer.wait_time = randf_range(0.5, 1.5)
	timer.timeout.connect(_on_state_timer_timeout)
	timer.start()


func _on_state_timer_timeout() -> void:
	timer.wait_time = randf_range(0.5, 1.5)
	current_state = Types.CharacterState.values().pick_random()
