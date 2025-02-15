extends Node2D


func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	pass


func _on_detection_system_body_entered(_body: Node2D) -> void:
	$Timer.start()


func _on_timer_timeout() -> void:
	%Label.self_modulate = 80
	%Label.show()
	%AnimationPlayer.play("TextShow")
