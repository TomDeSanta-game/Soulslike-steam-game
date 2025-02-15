extends BTAction

@export var group: StringName
@export var target_var: StringName = &"target"

var target: CharacterBody2D  # Added type hint


func _tick(_delta: float) -> Status:
	target = _get_target_node()
	if not is_instance_valid(target):
		return FAILURE

	blackboard.set_var(target_var, target)
	return SUCCESS


func _get_target_node() -> CharacterBody2D:
	var nodes: Array[Node] = agent.get_tree().get_nodes_in_group(group)

	match group:
		&"Enemy":
			if nodes.size() >= 2:
				while agent.check_for_self(nodes.front()):
					nodes.shuffle()
				return nodes.front() as CharacterBody2D
		&"Player":
			return nodes[0] as CharacterBody2D if nodes.size() > 0 else null

	return null
