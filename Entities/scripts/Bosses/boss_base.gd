# Version 1.0.0
extends CharacterBase
class_name BossBase

@export_group("Boss Properties")
@export var boss_name: String = "Boss"
@export var attack_damage: float = 25.0
@export var attack_range: float = 100.0
@export var attack_cooldown: float = 1.5
@export var detection_range: float = 300.0
@export var max_health: float = 500.0
@export var phase_health_thresholds: Array[float] = [0.7, 0.3]  # Trigger phase changes at 70% and 30% health

@export_group("Boss Combat")
@export var attack_patterns: Array[Dictionary] = []
@export var current_phase: int = 0
@export var is_phase_transitioning: bool = false

@onready var boss_hitbox: Node = %HitBox
@onready var boss_hurtbox: Node = %HurtBox
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var back_box: Area2D = $BackBox

# Add back damage properties
@export_group("Back Damage Properties")
@export var back_damage: float = 5.0  # Default back damage
@export var back_damage_cooldown: float = 1.0  # Cooldown for back damage
@export var continuous_damage_delay: float = 0.2  # Time needed for continuous collision damage

var target: Node2D = null
var can_attack: bool = true
var attack_timer: float = 0.0
var current_attack_pattern: Dictionary = {}
var can_deal_back_damage: bool = true  # Track if back damage is available

var _continuous_damage_timer: Timer
var _is_player_in_back_box: bool = false

const MOVEMENT_SPEEDS = {
	"WALK": 200.0,
	"RUN": 300.0,
	"DASH": 500.0,
}

@onready var frame_data_component: FrameDataComponent = $FrameDataComponent

func _ready() -> void:
	super._ready()
	_setup_boss()
	
	# Set initial health
	health_manager.set_vigour(int(max_health))
	
	# Set team to 2 (bosses)
	team = 2
	
	# Set collision layers/masks for boss
	collision_layer = C_Layers.LAYER_BOSS
	collision_mask = C_Layers.MASK_BOSS
	
	if boss_hitbox:
		boss_hitbox.hitbox_owner = self
		boss_hitbox.collision_layer = C_Layers.LAYER_HITBOX
		boss_hitbox.collision_mask = C_Layers.MASK_HITBOX
	
	if boss_hurtbox:
		boss_hurtbox.hurtbox_owner = self
		boss_hurtbox.collision_layer = C_Layers.LAYER_HURTBOX
		boss_hurtbox.collision_mask = C_Layers.MASK_HURTBOX

func _setup_boss() -> void:
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	if boss_hitbox:
		boss_hitbox.hitbox_owner = self
		boss_hitbox.damage = attack_damage
	
	if boss_hurtbox:
		boss_hurtbox.hurtbox_owner = self
	
	_setup_combat_components()
	_setup_frame_data()

func _physics_process(delta: float) -> void:
	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			can_attack = true
	
	_check_phase_transition()
	_update_boss_behavior(delta)

func _setup_combat_components() -> void:
	if boss_hitbox:
		boss_hitbox.hitbox_owner = self
		boss_hitbox.damage = attack_damage
		boss_hitbox.knockback_force = 300.0
		boss_hitbox.hit_stun_duration = 0.3
		if boss_hitbox.has_signal("hit_landed"):
			boss_hitbox.hit_landed.connect(_on_hit_landed)
	
	if boss_hurtbox:
		boss_hurtbox.hurtbox_owner = self
		if boss_hurtbox.has_signal("hit_taken"):
			boss_hurtbox.hit_taken.connect(_on_hit_taken)
	
	add_to_group("Boss")

func _check_phase_transition() -> void:
	if is_phase_transitioning:
		return
	
	var health_percentage = get_health_percentage()
	for i in range(phase_health_thresholds.size()):
		if health_percentage <= phase_health_thresholds[i] and current_phase == i:
			_transition_to_next_phase()
			break

func _transition_to_next_phase() -> void:
	is_phase_transitioning = true
	current_phase += 1
	
	# Emit signal for phase transition
	SignalBus.boss_phase_changed.emit(self, current_phase)
	
	# Override in child class to implement specific phase transition behavior
	_on_phase_transition()
	
	is_phase_transitioning = false

func _on_phase_transition() -> void:
	# Override in child class to implement specific phase transition behavior
	pass

func _update_boss_behavior(_delta: float) -> void:
	# Override in child class to implement specific boss behavior
	pass

func perform_attack(attack_name: String) -> void:
	if not can_attack:
		return
	
	can_attack = false
	attack_timer = attack_cooldown
	
	# Override in child class to implement specific attack patterns
	_execute_attack_pattern(attack_name)
	SignalBus.boss_attack_started.emit(self, attack_name)

func _execute_attack_pattern(_attack_name: String) -> void:
	# Override in child class to implement specific attack patterns
	pass

func move(move_direction: int, move_speed: float) -> void:
	# Apply movement
	velocity.x = move_direction * move_speed
	
	# Update animations based on movement
	if is_instance_valid(animated_sprite):
		if abs(velocity.x) > 0:
			animated_sprite.play("Run")
		else:
			animated_sprite.play("Idle")
	
	# Update facing direction
	_update_facing_direction(move_direction)
	
	# Apply movement
	move_and_slide()

func _update_facing_direction(face_direction: int) -> void:
	if not is_instance_valid(animated_sprite):
		return
	
	if face_direction != 0:
		var was_facing_left = animated_sprite.flip_h
		var face_left = face_direction < 0
		
		if was_facing_left != face_left:
			animated_sprite.flip_h = face_left
			
			# Update hitbox positions
			var current_scale = Vector2(-1 if face_left else 1, 1)
			for box in hitboxes:
				box.scale = current_scale
			
			# Update back box state when direction changes
			_update_back_box_state()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target = body
		SignalBus.player_detected.emit(self, body)

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") and body == target:
		SignalBus.player_lost.emit(self, body)
		target = null

func _on_hit_landed(_hitbox_node: Node, target_hurtbox: Node) -> void:
	if target_hurtbox.hurtbox_owner.has_method("take_damage"):
		target_hurtbox.hurtbox_owner.take_damage(attack_damage)
	if target_hurtbox.hurtbox_owner.is_in_group("Player") or target_hurtbox.is_in_group("Player_Hurtbox"):
		#SoundManager.play_sound(Sound.boss_hit, "SFX")
		pass

func _on_hit_taken(attacker_hitbox: Node, _defender_hitbox: Node) -> void:
	if attacker_hitbox.hitbox_owner and (attacker_hitbox.hitbox_owner.is_in_group("Player") or attacker_hitbox.is_in_group("Player_Hitbox")):
		take_damage(attacker_hitbox.damage)
		SignalBus.boss_damaged.emit(self, get_health(), get_max_health())

func take_damage(amount: float) -> void:
	super.take_damage(amount)
	if animated_sprite:
		animated_sprite.play("Hurt")

func get_health() -> float:
	return health_manager.get_health()

func get_max_health() -> float:
	return health_manager.get_max_health()

func get_health_percentage() -> float:
	return health_manager.get_health_percentage()

func _on_health_changed(new_health: float, _max_health: float) -> void:
	super._on_health_changed(new_health, _max_health)
	SignalBus.boss_damaged.emit(self, new_health, _max_health)

func _on_character_died() -> void:
	if animated_sprite:
		animated_sprite.play("Death")
		await animated_sprite.animation_finished
	die()

func die() -> void:
	SignalBus.boss_defeated.emit(self)
	queue_free()

func _setup_frame_data() -> void:
	var _frame_data_component = get_node_or_null("FrameDataComponent")
	if not _frame_data_component:
		return
	
	if not animated_sprite:
		push_error("AnimatedSprite2D not found in boss")
		return
	
	if boss_hitbox:
		frame_data_component.hitbox = boss_hitbox
		frame_data_component.update_frame_data()
	
	if boss_hurtbox:
		frame_data_component.hurtbox = boss_hurtbox
	
	if not animated_sprite.frame_changed.is_connected(_on_frame_changed):
		animated_sprite.frame_changed.connect(_on_frame_changed)
	if not animated_sprite.animation_changed.is_connected(_on_animation_changed):
		animated_sprite.animation_changed.connect(_on_animation_changed)

func _on_frame_changed() -> void:
	var _frame_data_component = get_node_or_null("FrameDataComponent")
	if _frame_data_component:
		_frame_data_component.update_frame_data()

func _on_animation_changed() -> void:
	var _frame_data_component = get_node_or_null("FrameDataComponent")
	if _frame_data_component:
		_frame_data_component.update_frame_data()
	
	# Update back box state when animation changes
	_update_back_box_state()

func setup_back_box() -> void:
	if not back_box:
		push_error("BackBox node not found in boss!")
		return
		
	# Configure back box collision properties
	back_box.collision_layer = 0  # The box doesn't need a layer
	back_box.collision_mask = C_Layers.LAYER_PLAYER  # Only detect player
	back_box.monitorable = false
	back_box.monitoring = true
	
	# Connect signals
	if not back_box.body_entered.is_connected(_on_back_box_body_entered):
		back_box.body_entered.connect(_on_back_box_body_entered)
	if not back_box.body_exited.is_connected(_on_back_box_body_exited):
		back_box.body_exited.connect(_on_back_box_body_exited)
	
	# Create cooldown timer for back damage
	var back_damage_timer = Timer.new()
	back_damage_timer.name = "BackDamageTimer"
	back_damage_timer.one_shot = true
	back_damage_timer.wait_time = back_damage_cooldown
	back_damage_timer.timeout.connect(_on_back_damage_timer_timeout)
	add_child(back_damage_timer)
	
	# Create continuous damage timer that repeats
	_continuous_damage_timer = Timer.new()
	_continuous_damage_timer.name = "ContinuousDamageTimer"
	_continuous_damage_timer.one_shot = false  # Changed to false so it keeps checking
	_continuous_damage_timer.wait_time = continuous_damage_delay
	_continuous_damage_timer.timeout.connect(_on_continuous_damage_timer_timeout)
	add_child(_continuous_damage_timer)
	
	# Initially enable the back box
	_update_back_box_state()

func _on_back_box_body_entered(body: Node2D) -> void:
	if not back_box or not back_box.monitoring:
		return
		
	if body.is_in_group("Player"):
		_is_player_in_back_box = true
		_continuous_damage_timer.start()  # Start checking continuously

func _on_back_box_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		_is_player_in_back_box = false
		_continuous_damage_timer.stop()  # Stop checking when player exits

func _on_back_damage_timer_timeout() -> void:
	can_deal_back_damage = true

func _on_continuous_damage_timer_timeout() -> void:
	if _is_player_in_back_box:  # If player is still in the box
		var player = get_tree().get_first_node_in_group("Player")
		if not player:
			return
			
		# Check if player is invincible
		if player.has_method("is_player_invincible") and player.is_player_invincible():
			return
			
		# Check if player was recently hit by a hitbox
		var player_path = player.get_path()
		if HitboxComponent._global_hit_cooldown.has(player_path):
			var time_since_last_hit = Time.get_ticks_msec() - HitboxComponent._global_hit_cooldown[player_path]
			if time_since_last_hit < HitboxComponent.GLOBAL_HIT_COOLDOWN_TIME * 1000:
				return
		
		if player.has_method("take_damage") and can_deal_back_damage:
			# Set global hit cooldown to prevent multiple damage sources
			HitboxComponent._global_hit_cooldown[player_path] = Time.get_ticks_msec()
			player.take_damage(back_damage)
			can_deal_back_damage = false
			if has_node("BackDamageTimer"):
				get_node("BackDamageTimer").start()

func _update_back_box_state() -> void:
	if not back_box or not animated_sprite:
		return
		
	# Disable back box during attack animation
	var is_attacking = animated_sprite.animation == "Attack"
	back_box.monitoring = not is_attacking
	back_box.monitorable = not is_attacking
	
	# Keep the collision shape enabled
	if back_box.get_node_or_null("CollisionShape2D"):
		back_box.get_node("CollisionShape2D").disabled = is_attacking
