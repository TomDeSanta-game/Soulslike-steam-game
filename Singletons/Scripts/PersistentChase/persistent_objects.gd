extends Node

# Dictionary to store persistent objects
var persistent_objects: Dictionary = {}

func add_persistent_object(object: Node, id: String) -> void:
	if persistent_objects.has(id):
		persistent_objects[id].queue_free()
	
	# Remove object from its current parent if it has one
	if object.get_parent():
		object.get_parent().remove_child(object)
	
	# Add the object as a child of this node
	add_child(object)
	persistent_objects[id] = object

func remove_persistent_object(id: String) -> void:
	if persistent_objects.has(id):
		persistent_objects[id].queue_free()
		persistent_objects.erase(id)

func get_persistent_object(id: String) -> Node:
	return persistent_objects.get(id)

func has_persistent_object(id: String) -> bool:
	return persistent_objects.has(id) 