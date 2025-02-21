extends PanelContainer

@onready var souls_amount_label: Label = %SoulsAmount

func _ready() -> void:
	# Wait one frame to ensure autoloads are ready
	await get_tree().process_frame
	
	# Connect to souls changed signal
	SignalBus.souls_changed.connect(_on_souls_changed)
	
	# Initialize with current souls amount
	var souls_system = get_node("/root/SoulsSystem")
	if souls_system:
		_update_display(souls_system.get_souls())
	else:
		push_error("SoulsSystem singleton not found! Make sure it's added to AutoLoad.")

func _on_souls_changed(amount: int) -> void:
	_update_display(amount)

func _update_display(amount: int) -> void:
	var souls_system = get_node("/root/SoulsSystem")
	if souls_system:
		souls_amount_label.text = souls_system.format_souls(amount)
	else:
		souls_amount_label.text = str(amount)
	
	# Optional animation for when souls change
	var tween = create_tween()
	tween.tween_property(souls_amount_label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(souls_amount_label, "scale", Vector2(1.0, 1.0), 0.1) 
