extends BTAction

@export var target_var: StringName = &"target"
@export var attack_range: float = 40.0
@export var slime_damage: float = 8.0
@export var attack_cooldown: float = 1.2
@export var poison_chance: float = 0.3
@export var poison_duration: float = 3.0
@export var poison_damage: float = 2.0

var cooldown_timer: float = 0.0
var actor: SlimyEnemy
var is_attacking: bool = false

func _tick(delta: float) -> Status:
	if not actor or not actor is SlimyEnemy:
		actor = agent as SlimyEnemy
		if not actor:
			return FAILURE
	
	# Get target from blackboard
	var target = blackboard.get_value(target_var)
	if not target or not is_instance_valid(target):
		return FAILURE
	
	# Update cooldown
	if cooldown_timer > 0:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			is_attacking = false
	
	# If we're attacking, keep running until attack is done
	if is_attacking:
		return RUNNING
	
	# If on cooldown, don't start new attack
	if cooldown_timer > 0:
		return FAILURE
	
	# Check if target is in range
	var distance = actor.global_position.distance_to(target.global_position)
	if distance > attack_range:
		return FAILURE
	
	# Face the target before attacking
	var direction = target.global_position.x - actor.global_position.x
	actor._update_facing_direction(sign(direction))
	
	# Start attack
	is_attacking = true
	actor.play_slime_attack()
	cooldown_timer = attack_cooldown
	
	return RUNNING 
