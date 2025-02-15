extends Node


func pause_all(nodes: Array):
	for node in nodes:
		pause(node)


func pause(node: Node):
	match node:
		AnimatedSprite2D:
			node.animation_speed = 0  # Stop the animation by setting speed to 0
		Area2D:
			node.motion = Vector2.ZERO  # Stop movement (if any)
		CharacterBody2D:
			node.velocity = Vector2.ZERO  # Stop movement (if any)
		Node2D:
			node.set_process(false)  # Stop processing (any logic inside _process)
		_:
			print("Unsupported node type:", node)


func choose(array: Array):
	array.shuffle()

	return array.front()


func unpause(node: Node):
	match node:
		AnimatedSprite2D:
			node.animation_speed = 1  # Restore the animation speed
		Area2D:
			node.motion = choose([Vector2.RIGHT, Vector2.LEFT])
		CharacterBody2D:
			node.velocity = choose([Vector2.RIGHT, Vector2.LEFT])
		Node2D:
			node.set_process(true)  # Restore processing
		_:
			print("Unsupported node type:", node)
