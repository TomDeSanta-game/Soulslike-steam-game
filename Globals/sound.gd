extends Node

# Player Sounds
var attack: AudioStream = preload(
	"res://assets/sounds/Player/_Sword_Attacks/Sword_Slash/attack.wav"
)
@warning_ignore("unused_private_class_variable")
var _attack: AudioStream = preload(
	"res://assets/sounds/Player/_Sword_Attacks/Sword_Slash/_attack.mp3"
)
var dash: AudioStream = preload("res://assets/sounds/Player/Dash/dash.ogg")
var death: AudioStream = preload("res://assets/sounds/Player/Death/death.wav")
var hit: AudioStream = preload("res://assets/sounds/Player/Hit/hit.mp3")
var oof: AudioStream = preload("res://assets/sounds/Player/Hurt/oof.wav")
var respawn: AudioStream = preload("res://assets/sounds/Player/Respawn/respawn.wav")
var run: AudioStream = preload("res://assets/sounds/Player/Run/run.wav")
var run_attack: AudioStream = preload(
	"res://assets/sounds/Player/_Sword_Attacks/Run_Attack/run_attack.wav"
)

var landing: AudioStream = preload("res://assets/sounds/Player/Landing/landing.mp3")

# Monster Sounds
var hurt: AudioStream = preload("res://assets/sounds/Monster/Hurt/hurt.mp3")
var monster_attack: AudioStream = preload("res://assets/sounds/Monster/Attack/monster-attack.mp3")

# Projectile Sounds
var explosion: AudioStream = preload("res://assets/sounds/Projectile/Explosion/explosion.mp3")
var projectile_hit: AudioStream = preload("res://assets/sounds/Projectile/Hit/proj_hit.wav")

# Collectible Sounds
var collect: AudioStream = preload("res://assets/sounds/Collectible/Collect/collect.mp3")

# Other Sounds
var heal: AudioStream = preload("res://assets/sounds/Other/Heal/heal.mp3")
