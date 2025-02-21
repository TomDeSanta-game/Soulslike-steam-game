extends Node2D


func _ready() -> void:
	SoundManager.set_music_volume(0.1)
	SoundManager.play_music(Sound.music)


func _process(_delta: float) -> void:
	pass
