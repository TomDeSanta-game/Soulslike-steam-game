extends Resource
class_name FrameData

@export var frame_number: int = 0
@export var hitboxes: Dictionary = {}  # Dictionary to store hitboxes
@export var hurtboxes: Dictionary = {}  # Dictionary to store hurtboxes
@export var damage: float = 10.0
@export var knockback: Vector2 = Vector2(100, -100)
