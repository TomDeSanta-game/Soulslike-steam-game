extends Area2D

@export var death_y_threshold: float = 100.0  # Distance below which player dies

func _ready() -> void:
	# Connect the body entered signal
	body_entered.connect(_on_body_entered)
	
	# Set up collision layer and mask for the doom pit
	collision_layer = 0  # The pit doesn't need a layer
	collision_mask = C_Layers.LAYER_PLAYER  # Only detect player

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		# Call the player's die function
		if body.has_method("_die"):
			body._die()
			# Try to load the scene first to verify it exists
			if ResourceLoader.exists("res://UI/Scenes/game_over.tscn"):
				SceneManager.change_scene("res://UI/Scenes/game_over.tscn")
			else:
				push_error("Could not find game over scene!")
		else:
			push_error("Player doesn't have _die method!")

# Called every frame to check for players below the threshold
func _physics_process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.global_position.y > global_position.y + death_y_threshold:
		if player.has_method("_die"):
			player._die() 