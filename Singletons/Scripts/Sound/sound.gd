extends Node

# Player Sounds
var attack: AudioStream = preload(
	"res://assets/Sounds/Player/_Sword_Attacks/Sword_Slash/attack.wav"
)
@warning_ignore("unused_private_class_variable")
var _attack: AudioStream = preload(
	"res://assets/Sounds/Player/_Sword_Attacks/Sword_Slash/_attack.mp3"
)
var dash: AudioStream = preload("res://assets/Sounds/Player/Dash/dash.ogg")
var death: AudioStream = preload("res://assets/Sounds/Player/Death/death.wav")
var hit: AudioStream = preload("res://assets/Sounds/Player/Hit/hit.mp3")
var hurt: AudioStream = preload("res://assets/Sounds/Player/Hurt/Hurt.mp3")
var respawn: AudioStream = preload("res://assets/Sounds/Player/Respawn/respawn.wav")
var run_attack: AudioStream = preload(
	"res://assets/Sounds/Player/_Sword_Attacks/Run_Attack/run_attack.wav"
)


# Monster Sounds
var monster_hurt: AudioStream = preload("res://assets/Sounds/Monster/Hurt/hurt.mp3")
var monster_attack: AudioStream = preload("res://assets/Sounds/Monster/Attack/monster-attack.mp3")


# Collectible Sounds
var collect: AudioStream = preload("res://assets/Sounds/Collectible/Collect/collect.mp3")

# Other Sounds
var heal: AudioStream = preload("res://assets/Sounds/Other/Heal/heal.mp3")

# Music
var music: AudioStream = preload("res://assets/Music/music.mp3")

# Interface
var menu_select: AudioStream = preload("res://assets/Sounds/Menu/menu_select.mp3")

var sell: AudioStream = preload("res://assets/Sounds/Menu/sell.mp3")
