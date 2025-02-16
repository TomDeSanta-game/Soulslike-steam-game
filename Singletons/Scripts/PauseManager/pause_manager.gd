extends Node


func pause_all(nodes: Array):
	for node in nodes:
		pause(node)


func pause(node: Node):
	if node is AnimatedSprite2D:
		node.animation_speed = 0  # Stop the animation by setting speed to 0
	elif node is Area2D:
		node.motion = Vector2.ZERO  # Stop movement (if any)
	elif node is CharacterBody2D:
		node.set_physics_process(false)  # Stop physics processing
		if node.has_method("set_process"):
			node.set_process(false)  # Stop regular processing
	elif node is Node2D:
		node.set_process(false)  # Stop processing (any logic inside _process)
	else:
		print("Unsupported node type:", node)


func choose(array: Array):
	array.shuffle()

	return array.front()


func unpause(node: Node):
	if node is AnimatedSprite2D:
		node.animation_speed = 1  # Restore the animation speed
	elif node is Area2D:
		node.motion = choose([Vector2.RIGHT, Vector2.LEFT])
	elif node is CharacterBody2D:
		node.set_physics_process(true)  # Restore physics processing
		if node.has_method("set_process"):
			node.set_process(true)  # Restore regular processing
	elif node is Node2D:
		node.set_process(true)  # Restore processing
	else:
		print("Unsupported node type:", node)
