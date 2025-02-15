class_name Types extends Node

@warning_ignore("unused_signal")
signal on_create_projectile(
	pos: Vector2, dir: Vector2, life_span: float, speed: float, ob_type: ObjectType
)

# ObjectType
enum ObjectType { EXPLOSION, SHURIKEN }

# CharacterState
enum CharacterState { IDLE, NEW_DIRECTION, MOVE }

# Gravity_Constant
const GRAVITY_CONSTANT: float = 900.0

# Times
var days: int
var hours: int
var minutes: int
var seconds: int

# Player
var player: CharacterBody2D
var player_name: String

# Class Chosen
var class_chosen: String
