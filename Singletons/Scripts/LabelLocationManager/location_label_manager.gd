extends Node

@warning_ignore("unused_signal")
signal location_entered(location_name)

var label = null
var tween: Tween

func _ready() -> void:
	# Get the label from the scene tree when it's ready
	call_deferred("_setup_label")

func _setup_label() -> void:
	label = get_tree().get_first_node_in_group("PlaceLabel")
	if label and is_instance_valid(label):
		label.visible = false
		label.modulate.a = 0.0

func show_location_label(location_name: String) -> void:
	if not label or not is_instance_valid(label):
		_setup_label()
		if not label or not is_instance_valid(label):
			return
	
	label.text = location_name
	
	if tween and tween.is_valid():
		tween.kill()
		tween = null
	
	if not is_instance_valid(label):
		return
		
	label.visible = true
	tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Initial fade in
	tween.tween_property(label, "modulate:a", 0.0, 0.0)  # Reset to fully transparent
	tween.tween_property(label, "modulate:a", 1.0, 2.0)  # Slow fade in
	
	# First pulse
	tween.tween_property(label, "modulate:a", 0.6, 0.7)
	tween.tween_property(label, "modulate:a", 1.0, 0.7)
	
	# Second pulse
	tween.tween_property(label, "modulate:a", 0.6, 0.7)
	tween.tween_property(label, "modulate:a", 1.0, 0.7)
	
	# Final fade out
	tween.tween_property(label, "modulate:a", 0.0, 2.0)
	tween.tween_callback(func(): 
		if is_instance_valid(label):
			label.visible = false
	) 