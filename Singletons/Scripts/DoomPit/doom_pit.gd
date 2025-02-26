extends Area2D

@export var death_y_threshold: float = 200.0  # Distance below which player dies
var _is_player_dying: bool = false  # Flag to prevent multiple death calls

func _ready() -> void:
	# Connect the body entered signal
	body_entered.connect(_on_body_entered)
	
	# Set up collision layer and mask for the doom pit
	collision_layer = 0  # The pit doesn't need a layer
	collision_mask = C_Layers.LAYER_PLAYER  # Only detect player

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not _is_player_dying:
		# Call the player's die function
		if body.has_method("_die"):
			_is_player_dying = true
			body._die()
		else:
			push_error("Player doesn't have _die method!")

# Called every frame to check for players below the threshold
func _physics_process(_delta: float) -> void:
	if _is_player_dying:  # Skip check if player is already dying
		return
		
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.global_position.y > global_position.y + death_y_threshold:
		if player.has_method("_die"):
			_is_player_dying = true
			player._die() 