class_name Types extends Node

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
