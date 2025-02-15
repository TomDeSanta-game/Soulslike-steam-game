extends Node

# Player Sounds
var attack: AudioStream = preload(
	"res://assets/sounds/Player/_Sword_Attacks/Sword_Slash/attack.wav"
)

@warning_ignore("unused_private_class_variable")
var _attack: AudioStream = preload(
	"res://assets/sounds/Player/_Sword_Attacks/Sword_Slash/_attack.mp3"
)

var run_attack: AudioStream = preload(
	"res://assets/sounds/Player/_Sword_Attacks/Run_Attack/run_attack.wav"
)

var death: AudioStream = preload("res://assets/sounds/Player/Death/death.wav")

var respawn: AudioStream = preload("res://assets/sounds/Player/Respawn/respawn.wav")

var oof: AudioStream = preload("res://assets/sounds/Player/Hurt/oof.wav")

var run: AudioStream = preload("res://assets/sounds/Player/Run/run.wav")

# Hit Sound
var hit: AudioStream = preload("res://assets/sounds/Player/_Sword_Attacks/Sword_Slash/attack.wav")  # Reusing attack sound for hit effect

# Monster Sounds
var monster_attack: AudioStream = preload("res://assets/sounds/Monster/Attack/monster-attack.mp3")

# Projectile Sounds
var projectile_hit: AudioStream = preload("res://assets/sounds/Projectile/Hit/proj_hit.wav")

var explosion: AudioStream = preload("res://assets/sounds/Projectile/Explosion/explosion.mp3")
