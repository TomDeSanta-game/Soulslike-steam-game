extends Node2D

@onready var timer: Timer = $Timer
@onready var detection_system: Area2D = $DetectionSystem

# Elevator variables
@onready var elevator: Node2D = $Elevator
@onready var elevator_animation_player: AnimationPlayer = $Elevator/AnimationPlayer

var has_shown_label := false
var elevator_moving := false
var elevator_at_top := false

func _ready() -> void:
	# Set up detection system collision
	if detection_system:
		detection_system.collision_layer = 0
		detection_system.collision_mask = 8  # Layer 4 (PLAYER)
	
	# Set up elevator trigger area
	if has_node("ElevatorTrigger"):
		var trigger = $ElevatorTrigger
		trigger.collision_layer = 0
		trigger.collision_mask = 8  # Layer 4 (PLAYER)
		trigger.connect("body_entered", _on_elevator_trigger_body_entered)
	
	# Connect animation player signals
	if elevator_animation_player:
		elevator_animation_player.connect("animation_finished", _on_elevator_animation_finished)

func _process(_delta: float) -> void:
	pass

func _on_detection_system_body_entered(_body: Node2D) -> void:
	if _body.is_in_group("Player") and not has_shown_label:
		has_shown_label = true
		LocationLabelManager.show_location_label("The Caves")

func _on_doom_pit_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		# Call die() on the player
		if body.has_method("_die"):
			body._die()
		# The player's _die() function will handle the transition to game over scene

func _on_elevator_trigger_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not elevator_moving and elevator and elevator_animation_player:
		move_elevator()

func move_elevator() -> void:
	if elevator_moving or not elevator or not elevator_animation_player:
		return
	
	elevator_moving = true
	
	# Emit signal that elevator started moving
	if SignalBus.has_signal("elevator_started_moving"):
		SignalBus.elevator_started_moving.emit(elevator)
	
	# Check which animation to play based on current position
	if elevator_at_top:
		# Move elevator down
		elevator_animation_player.play("move_down")
	else:
		# Move elevator up
		elevator_animation_player.play("move_up")

func _on_elevator_animation_finished(anim_name: String) -> void:
	elevator_moving = false
	
	# Update elevator position state
	if anim_name == "move_up":
		elevator_at_top = true
		if SignalBus.has_signal("elevator_reached_top"):
			SignalBus.elevator_reached_top.emit(elevator)
	elif anim_name == "move_down":
		elevator_at_top = false
		if SignalBus.has_signal("elevator_reached_bottom"):
			SignalBus.elevator_reached_bottom.emit(elevator)
	
	# Emit signal that elevator stopped moving
	if SignalBus.has_signal("elevator_stopped_moving"):
		SignalBus.elevator_stopped_moving.emit(elevator)
