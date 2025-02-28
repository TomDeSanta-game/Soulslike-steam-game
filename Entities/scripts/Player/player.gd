extends CharacterBase

# Constants and Configuration
const STATS: Dictionary = {
	"MAX_MAGIC": 100.0,
	"MAGIC_COST": 10.0,
	"LIFESTEAL_PERCENT": 15.0,  # Percentage of damage dealt that will be returned as health
	"MIN_LIFESTEAL_AMOUNT": 1.0,  # Minimum amount of health restored per hit
	"MAX_LIFESTEAL_AMOUNT": 25.0,  # Maximum amount of health restored per hit
	"DASH_SPEED": 1200.0,  # Increased from 800 to 1200 for faster dash
	"DASH_DURATION": 0.1,  # Reduced from 0.15 to 0.1 for faster dash
	"DASH_COOLDOWN": 0.5,  # Time before can dash again
	"MAX_STAMINA": 200.0,  # Increased from 100 to 200
	"STAMINA_REGEN_RATE": 20.0,  # Stamina points per second
	"ATTACK_STAMINA_COST": 10.0,
	"RUN_ATTACK_STAMINA_COST": 20.0,
	"RUN_STAMINA_DRAIN_RATE": 5.55,  # Drains full stamina if running too long
	"COYOTE_TIME": 0.15,  # 150ms of coyote time
	"WALL_CLIMB_STAMINA_DRAIN": 15.0,  # Stamina drain per second while wall climbing
	"WALL_CLIMB_SPEED": -10.0,  # Upward speed while wall climbing (-10 means up)
	"WALL_GRAB_CHECK_DISTANCE": 5.0,  # How far to check for walls
}

const ANIMATIONS: Dictionary = {"IDLE": "Idle", "RUN": "Run", "JUMP": "Jump", "ATTACK": "Attack", "CROUCH": "Crouch", "CROUCH_RUN": "Crouch_Run", "DASH": "Dash", "DEATH": "Death", "FALL": "Fall", "HURT": "Hurt", "ROLL": "Roll", "RUN_ATTACK": "Run_Attack", "SLIDE": "Slide", "WALL_CLIMB": "Wall_Climb", "WALL_HANG": "Wall_Hang"}

# Node references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var label: Label = $UILayer/Label
@onready var health_bar: ProgressBar = $UILayer/ProgressBar
@onready var stamina_bar: ProgressBar = $UILayer/StaminaBar
@onready var camera: Camera2D = $Camera2D
@onready var grab_collision_shape: CollisionShape2D = $GrabCollisionShape
@onready var place_label: Label = $UILayer/PlaceLabel

# Types Global
@onready var types: Types = Types.new()

# Timers
@onready var time_taken_damage_timer: Timer = $Timers/TimeTakenDamageTimer
@onready var hurt_timer: Timer = $Timers/HurtTimer
@onready var attack_timer: Timer = $Timers/AttackTimer
@onready var crouch_attack_timer: Timer = $Timers/CrouchAttackTimer
@onready var death_timer: Timer = $Timers/DeathTimer

# Player Group
@export_group("Shaders")
@export var _shader_material: ShaderMaterial
@export var _death_shader_material: ShaderMaterial
@export var _dash_shader_material: ShaderMaterial
@export var _invincibility_shader_material: ShaderMaterial

# Player state
var magic: float = STATS.MAX_MAGIC
var stamina: float = STATS.MAX_STAMINA
var direction: float = 0.0
var is_attacking: bool = false
var is_crouching: bool = false
var current_state: Types.CharacterState = Types.CharacterState.IDLE

# Fade Variables
var fade_duration: float = 2.0  # Duration of the fade effect
var fade_timer: float = 0.0  # Timer for the fade effect
var is_fading: bool = false  # Track if the fade effect is active

const MOVEMENT_SPEEDS = {
	"WALK": 300.0,
	"RUN": 400.0,
	"CROUCH": 150.0,
}

# Health Variables
var current_health: float
var max_health: float
var health_percent: float
var health_regen_rate: float = 0.5
var can_heal: bool = false

# Damage Shader
var effect_duration: float = 1.66666666667  # Duration of the effect
var effect_timer: float = 0.0  # Timer for the effect

# FrameData System
@onready var frame_data_component: FrameDataComponent = %FrameDataComponent

var current_animation: String = ""
var current_frame: int = 0

# Jump-Cutting System
var is_jump_held: bool = false
var is_jump_active: bool = false

# Jump Timer
@onready var jump_timer: Timer = Timer.new()

# State Machine
@onready var state_machine: PlayerStateMachine = PlayerStateMachine.new()

# Acceleration and Deceleration
var acceleration_frames: int = 12
var deceleration_frames: int = 18
var deceleration_counter: int = 0
var current_acceleration_frame: int = 0
var target_speed: float = 0.0

# Debug Colors
const DEBUG_COLORS = {"HITBOX": Color(1, 0, 0, 0.5), "HURTBOX": Color(0, 1, 0, 0.5)}

@onready var hitbox: HitboxComponent = %Hitbox
@onready var hurtbox: HurtboxComponent = %Hurtbox

# Dash Variables
var can_dash: bool = true
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: float = 1.0

# Save Engine
@onready var save_engine: Node = get_node("/root/SaveEngine")

# Coyote Time Variables
var coyote_timer: float = 0.0
var has_coyote_time: bool = false

# Invincibility Variables
var invincibility_duration: float = 2.0  # Total duration of invincibility
var invincibility_timer: float = 0.0

# Add this near other class variables
var last_floor_position: Vector2 = Vector2.ZERO

# Add near other class variables
var is_grabbing: bool = false

# Add these new variables near the top with other class variables
@onready var ledge_check: RayCast2D = $LedgeCheck
@onready var ledge_climb_position: Marker2D = $LedgeClimbPosition

# Add near the top with other class variables
var is_ledge_climbing: bool = false

# Add near other @onready vars
@onready var ui_layer: CanvasLayer = $UILayer

# UI Elements
@onready var xp_display: Node = null
@onready var level_up_menu: Node = null

# Add near other class variables
var gravity_enabled: bool = true

# Add near other class variables
var current_merchant: Node = null

@export var merchant_menu_scene_resource: PackedScene = preload("res://UI/Scenes/MerchantMenu.tscn")
var merchant_menu: MerchantMenu = null

# Add a class variable to track if death transition is in progress
var _is_death_transition_active: bool = false

@onready var fell_label: Label = %FellLabel


func _ready() -> void:
	# Add only the player node to the Player group
	add_to_group("Player")

	super._ready()  # Call parent _ready to initialize health manager
	types.player = self

	place_label.add_to_group("PlaceLabel")

	fell_label.add_to_group("FellLabel")

	# Connect item used signal
	SignalBus.item_used.connect(_on_item_used)

	# Set collision layers and masks
	self.collision_layer = C_Layers.LAYER_PLAYER
	self.collision_mask = C_Layers.MASK_PLAYER

	# Also set the hitbox and hurtbox layers/masks
	if hitbox:
		hitbox.hitbox_owner = self
		hitbox.damage = 15.0
		hitbox.knockback_force = 200.0
		hitbox.hit_stun_duration = 0.2
		hitbox.collision_layer = C_Layers.LAYER_HITBOX
		hitbox.collision_mask = C_Layers.MASK_HITBOX
		hitbox.add_to_group("Player_Hitbox")
		hitbox.active = true

	if hurtbox:
		hurtbox.hurtbox_owner = self
		hurtbox.collision_layer = C_Layers.LAYER_HURTBOX
		hurtbox.collision_mask = C_Layers.MASK_HURTBOX
		hurtbox.add_to_group("Player_Hurtbox")
		hurtbox.active = true

	set_jump_power(-410.0)

	# Get initial health values
	current_health = health_manager.get_health()
	max_health = health_manager.get_max_health()
	health_percent = health_manager.get_health_percentage()

	# Setup health bar style
	var health_bar_style = StyleBoxFlat.new()
	health_bar_style.bg_color = Color.from_string("#ff0033", Color.RED)  # Vibrant red
	health_bar_style.corner_radius_top_left = 12
	health_bar_style.corner_radius_top_right = 12
	health_bar_style.corner_radius_bottom_right = 0  # Remove bottom corners
	health_bar_style.corner_radius_bottom_left = 0  # Remove bottom corners
	health_bar_style.border_width_left = 3
	health_bar_style.border_width_top = 3
	health_bar_style.border_width_right = 3
	health_bar_style.border_width_bottom = 3
	health_bar_style.border_color = Color(0.9, 0.9, 0.9, 0.7)  # Lighter border
	health_bar_style.shadow_color = Color(0, 0, 0, 0.4)
	health_bar_style.shadow_size = 6
	health_bar_style.anti_aliasing = true
	health_bar_style.expand_margin_left = 4
	health_bar_style.expand_margin_right = 4
	health_bar_style.expand_margin_top = 4
	health_bar_style.expand_margin_bottom = 4

	var health_bar_bg_style = StyleBoxFlat.new()
	health_bar_bg_style.bg_color = Color.from_string("#1a1a1a", Color.BLACK)  # Darker background
	health_bar_bg_style.corner_radius_top_left = 12
	health_bar_bg_style.corner_radius_top_right = 12
	health_bar_bg_style.corner_radius_bottom_right = 0  # Remove bottom corners
	health_bar_bg_style.corner_radius_bottom_left = 0  # Remove bottom corners
	health_bar_bg_style.border_width_left = 3
	health_bar_bg_style.border_width_top = 3
	health_bar_bg_style.border_width_right = 3
	health_bar_bg_style.border_width_bottom = 3
	health_bar_bg_style.border_color = Color(0.3, 0.3, 0.3, 0.6)  # Darker border
	health_bar_bg_style.shadow_color = Color(0, 0, 0, 0.3)
	health_bar_bg_style.shadow_size = 4
	health_bar_bg_style.anti_aliasing = true
	health_bar_bg_style.expand_margin_left = 4
	health_bar_bg_style.expand_margin_right = 4
	health_bar_bg_style.expand_margin_top = 4
	health_bar_bg_style.expand_margin_bottom = 4

	# Setup stamina bar style
	var stamina_bar_style = StyleBoxFlat.new()
	stamina_bar_style.bg_color = Color.from_string("#00cc66", Color.GREEN)  # Vibrant green
	stamina_bar_style.corner_radius_top_left = 0  # Remove top corners
	stamina_bar_style.corner_radius_top_right = 0  # Remove top corners
	stamina_bar_style.corner_radius_bottom_right = 12
	stamina_bar_style.corner_radius_bottom_left = 12
	stamina_bar_style.border_width_left = 3
	stamina_bar_style.border_width_top = 3
	stamina_bar_style.border_width_right = 3
	stamina_bar_style.border_width_bottom = 3
	stamina_bar_style.border_color = Color(0.9, 0.9, 0.9, 0.7)  # Lighter border
	stamina_bar_style.shadow_color = Color(0, 0, 0, 0.4)
	stamina_bar_style.shadow_size = 6
	stamina_bar_style.anti_aliasing = true
	stamina_bar_style.expand_margin_left = 4
	stamina_bar_style.expand_margin_right = 4
	stamina_bar_style.expand_margin_top = 4
	stamina_bar_style.expand_margin_bottom = 4

	var stamina_bar_bg_style = StyleBoxFlat.new()
	stamina_bar_bg_style.bg_color = Color.from_string("#1a1a1a", Color.BLACK)  # Darker background
	stamina_bar_bg_style.corner_radius_top_left = 0  # Remove top corners
	stamina_bar_bg_style.corner_radius_top_right = 0  # Remove top corners
	stamina_bar_bg_style.corner_radius_bottom_right = 12
	stamina_bar_bg_style.corner_radius_bottom_left = 12
	stamina_bar_bg_style.border_width_left = 3
	stamina_bar_bg_style.border_width_top = 3
	stamina_bar_bg_style.border_width_right = 3
	stamina_bar_bg_style.border_width_bottom = 3
	stamina_bar_bg_style.border_color = Color(0.3, 0.3, 0.3, 0.6)  # Darker border
	stamina_bar_bg_style.shadow_color = Color(0, 0, 0, 0.3)
	stamina_bar_bg_style.shadow_size = 4
	stamina_bar_bg_style.anti_aliasing = true
	stamina_bar_bg_style.expand_margin_left = 4
	stamina_bar_bg_style.expand_margin_right = 4
	stamina_bar_bg_style.expand_margin_top = 4
	stamina_bar_bg_style.expand_margin_bottom = 4

	# Apply styles to health bar
	health_bar.add_theme_stylebox_override("fill", health_bar_style)
	health_bar.add_theme_stylebox_override("background", health_bar_bg_style)
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.min_value = 0
	health_bar.custom_minimum_size = Vector2(250, 35)  # Make the bar wider and taller
	health_bar.modulate.a = 0.95  # Slightly transparent

	# Apply styles to stamina bar
	stamina_bar.add_theme_stylebox_override("fill", stamina_bar_style)
	stamina_bar.add_theme_stylebox_override("background", stamina_bar_bg_style)
	stamina_bar.max_value = STATS.MAX_STAMINA
	stamina_bar.value = stamina
	stamina_bar.min_value = 0
	stamina_bar.custom_minimum_size = Vector2(250, 35)  # Make the bar wider and taller
	stamina_bar.modulate.a = 0.95  # Slightly transparent

	# Create a Control node to maintain stamina bar position
	var stamina_container = Control.new()
	stamina_container.custom_minimum_size = stamina_bar.custom_minimum_size
	stamina_container.size = stamina_bar.size

	# Get the parent of the stamina bar
	var stamina_parent = stamina_bar.get_parent()
	if stamina_parent:
		# Remove stamina bar from its current parent
		stamina_parent.remove_child(stamina_bar)
		# Add container to parent
		stamina_parent.add_child(stamina_container)
		# Add stamina bar to container
		stamina_container.add_child(stamina_bar)

		# Position container relative to health bar
		stamina_container.position.y = health_bar.position.y + health_bar.size.y + 8
		stamina_container.position.x = health_bar.position.x

		# Reset stamina bar position within container
		stamina_bar.position = Vector2.ZERO

	# Setup UI displays
	_setup_ui_displays()

	add_child(state_machine)

	add_child(jump_timer)

	jump_timer.wait_time = 1.0
	jump_timer.one_shot = true
	jump_timer.timeout.connect(_jump_timer_timeout)

	animated_sprite.material = _shader_material

	base_run_speed = MOVEMENT_SPEEDS.RUN
	base_crouch_speed = MOVEMENT_SPEEDS.CROUCH

	frame_data_component.sprite = animated_sprite
	frame_data_component.hitbox = hitbox
	frame_data_component.hurtbox = hurtbox

	# Connect animated sprite signals
	animated_sprite.animation_changed.connect(_on_animation_changed)
	animated_sprite.animation_finished.connect(_on_animation_finished)

	_setup_commands()
	_connect_signals()

	state_machine.init(self)

	# Connect attack signals through SignalBus
	SignalBus.attack_started.connect(_on_attack_started)
	SignalBus.attack_ended.connect(_on_attack_ended)

	# Connect frame changed signal for redrawing
	if !animated_sprite.frame_changed.is_connected(_on_frame_changed):
		animated_sprite.frame_changed.connect(_on_frame_changed)

	# Connect hitbox and hurtbox signals through SignalBus
	if !SignalBus.hit_landed.is_connected(_on_hit_landed):
		SignalBus.hit_landed.connect(_on_hit_landed)
	if !SignalBus.hit_taken.is_connected(_on_hit_taken):
		SignalBus.hit_taken.connect(_on_hit_taken)

	# Initialize frame data
	_frame_data_init()
	frame_data_component.update_frame_data()  # Initial frame data update

	# Load saved game data if it exists
	if save_engine.load_game():
		_load_player_state(save_engine.get_save_data())

	# Disable grab collision shape by default
	if grab_collision_shape:
		grab_collision_shape.disabled = true

	# Initialize merchant menu
	merchant_menu = merchant_menu_scene_resource.instantiate()
	ui_layer.add_child(merchant_menu)
	merchant_menu.visible = false

	# Setup collection area if it doesn't exist
	if not has_node("CollectionArea"):
		var collection_area = Area2D.new()
		collection_area.name = "CollectionArea"
		add_child(collection_area)

		# Add collision shape
		var collection_shape = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 20.0  # Adjust radius as needed
		collection_shape.shape = shape
		collection_area.add_child(collection_shape)

		# Set proper collision layer and mask for collection
		collection_area.collision_layer = C_Layers.LAYER_PLAYER
		collection_area.collision_mask = C_Layers.LAYER_COLLECTIBLE
	else:
		var collection_area = get_node("CollectionArea")
		collection_area.collision_layer = C_Layers.LAYER_PLAYER
		collection_area.collision_mask = C_Layers.LAYER_COLLECTIBLE


func _process(delta: float) -> void:
	if effect_timer > 0.0:
		effect_timer -= delta
		# Calculate the progress of the effect (0.0 to 1.0)
		var progress = 1.0 - (effect_timer / effect_duration)
		_shader_material.set_shader_parameter("effect_progress", progress)
	else:
		# Reset the effect progress when the timer is done
		_shader_material.set_shader_parameter("effect_progress", 0.0)

	if is_fading:
		fade_timer += delta
		# Calculate the fade progress (0.0 to 1.0)
		var progress = min(fade_timer / fade_duration, 1.0)
		_death_shader_material.set_shader_parameter("fade_progress", progress)

		# If the fade is complete, queue free the player
		if progress >= 1.0:
			pass

	_health_regen(delta)
	_stamina_regen(delta)
	_update_player_state()
	_update_ui()
	_update_health_bar()
	_update_stamina_bar()

	# Handle invincibility effect
	if is_invincible:
		invincibility_timer += delta
		_invincibility_shader_material.set_shader_parameter("time_elapsed", invincibility_timer)

		if invincibility_timer >= invincibility_duration:
			_end_invincibility()


func _physics_process(delta: float) -> void:
	var was_on_floor = is_on_floor()

	# Handle wall climbing stamina drain and movement
	if is_grabbing:
		if is_on_wall() and _has_enough_stamina(STATS.WALL_CLIMB_STAMINA_DRAIN * delta):
			velocity.y = STATS.WALL_CLIMB_SPEED
			_use_stamina(STATS.WALL_CLIMB_STAMINA_DRAIN * delta)
			animated_sprite.play(ANIMATIONS.WALL_CLIMB)

			# Check if we can climb the ledge
			if _can_climb_ledge():
				_start_ledge_climb()
		else:
			_end_grab()  # Let go if not on wall or out of stamina

	if !is_on_floor() and !is_grabbing and gravity_enabled:  # Only apply gravity if enabled
		velocity.y += Types.GRAVITY_CONSTANT * delta
		# Only play fall animation when moving downward and not in a jump state
		if velocity.y > 0 and !is_jump_active and !is_attacking and animated_sprite.animation != ANIMATIONS.JUMP:  # Check animation instead of state
			state_machine.dispatch(&"fall")
	elif was_on_floor:
		# Update last floor position when on floor
		last_floor_position = global_position

	# Handle coyote time
	if was_on_floor and !is_on_floor():
		coyote_timer = STATS.COYOTE_TIME
		has_coyote_time = true
	elif is_on_floor():
		has_coyote_time = false
		coyote_timer = 0.0
		is_jump_active = false  # Reset jump active when landing
	elif coyote_timer > 0:
		coyote_timer -= delta
		if coyote_timer <= 0:
			has_coyote_time = false

	# Jump cutting logic
	if is_jump_active and not is_jump_held and velocity.y < 0:
		velocity.y = 0  # Stop upward movement if jump button is released
		is_jump_active = false
		if !is_on_floor():  # If we're in the air after cutting jump, transition to fall
			state_machine.dispatch(&"fall")

	# Handle dash cooldown
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer <= 0:
			can_dash = true

	# Handle active dash
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			velocity.x = dash_direction * MOVEMENT_SPEEDS.RUN  # Maintain some momentum after dash
		else:
			# Apply dash velocity
			velocity.x = dash_direction * STATS.DASH_SPEED
			# Keep y velocity at 0 during dash
			velocity.y = 0

	# Handle running stamina drain
	if _is_running():
		_use_stamina(STATS.RUN_STAMINA_DRAIN_RATE * delta)

	if not is_dashing:
		_handle_movement()
	move_and_slide()


# NOTE: Main Frame Data Initialization ( Player )
func _frame_data_init() -> void:
	# Initialize frame data component with all required nodes
	if frame_data_component and animated_sprite and hitbox and hurtbox:
		frame_data_component.sprite = animated_sprite
		frame_data_component.hitbox = hitbox
		frame_data_component.hurtbox = hurtbox

		# Connect animation signals only once
		if !animated_sprite.frame_changed.is_connected(_on_frame_changed):
			animated_sprite.frame_changed.connect(_on_frame_changed)
		if !animated_sprite.animation_changed.is_connected(_on_animation_changed):
			animated_sprite.animation_changed.connect(_on_animation_changed)
		if !animated_sprite.animation_finished.is_connected(_on_animation_finished):
			animated_sprite.animation_finished.connect(_on_animation_finished)
	else:
		push_error("Player: Missing required nodes for frame data initialization")


func _setup_commands() -> void:
	LimboConsole.register_command(_die)


func _unhandled_input(event: InputEvent) -> void:
	_handle_input(event)


func _trigger_effect() -> void:
	effect_timer = effect_duration


# Update the healthbar
func _update_health_bar() -> void:
	# Create a smooth tween for health bar updates
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(health_bar, "value", current_health, 0.4)

	# Dynamic color change based on health percentage
	var health_style = health_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if health_style:
		var current_health_percent = (current_health / max_health) * 100
		var new_color: Color
		if current_health_percent > 60:
			new_color = Color.from_string("#ff0033", Color.RED)  # Full health color
		elif current_health_percent > 30:
			new_color = Color.from_string("#ff9900", Color.ORANGE)  # Medium health color
		else:
			new_color = Color.from_string("#ff0000", Color.RED)  # Low health color

		# Tween the color change
		tween.parallel().tween_method(func(c): health_style.bg_color = c, health_style.bg_color, new_color, 0.4)

	# Flash effect when taking damage
	if health_bar.value > current_health:
		var flash_tween = create_tween()
		flash_tween.tween_property(health_bar, "modulate", Color(2, 2, 2, 1), 0.1)
		flash_tween.tween_property(health_bar, "modulate", Color(1, 1, 1, 0.95), 0.2)

		# Screen shake effect on significant damage
		if (health_bar.value - current_health) > max_health * 0.1:  # More than 10% damage
			camera.shake(10, 0.3, 0.85)


# Movement System
func _handle_movement() -> void:
	direction = Input.get_axis("LEFT", "RIGHT")
	var speed = _get_current_speed()

	# Apply air control (reduced speed) when in the air
	if !is_on_floor():
		speed *= 0.6  # Reduce speed to 60% while in air

	if current_state == Types.CharacterState.IDLE or current_state == Types.CharacterState.MOVE:
		if direction != 0:
			deceleration_counter = 0  # Reset deceleration counter when moving
			target_speed = speed * sign(direction)
			if current_acceleration_frame < acceleration_frames:
				current_acceleration_frame += 1
			var acceleration_factor = float(current_acceleration_frame) / acceleration_frames
			velocity.x = lerp(velocity.x, target_speed, acceleration_factor)
		else:
			current_acceleration_frame = 0  # Reset acceleration when not moving
			if abs(velocity.x) > 0:
				deceleration_counter = min(deceleration_counter + 1, deceleration_frames)
				var deceleration_progress = float(deceleration_counter) / deceleration_frames
				velocity.x = lerp(velocity.x, 0.0, deceleration_progress)

	_update_sprite_direction()
	_update_movement_state()


func _get_current_speed() -> float:
	# Return different speeds based on current state
	if is_crouching:
		return MOVEMENT_SPEEDS.CROUCH
	if _is_running():
		return MOVEMENT_SPEEDS.RUN
	return MOVEMENT_SPEEDS.WALK


func _update_movement_state() -> void:
	if abs(velocity.x) > 5.0:  # Small threshold to avoid floating point issues
		if !is_attacking and !is_jump_active and is_on_floor():
			animated_sprite.play(ANIMATIONS.RUN)
	else:
		velocity.x = 0  # Snap to zero when very slow
		if !is_attacking and !is_jump_active and is_on_floor():
			animated_sprite.play(ANIMATIONS.IDLE)


func _reset_acceleration() -> void:
	current_acceleration_frame = 0
	target_speed = 0.0


func _update_sprite_direction() -> void:
	if direction != 0:
		var was_flipped = animated_sprite.flip_h
		animated_sprite.flip_h = direction < 0
		if was_flipped != animated_sprite.flip_h:
			queue_redraw()  # Only redraw if flip state changed


# State Management
func _update_player_state() -> void:
	is_attacking = _is_attack_animation()
	is_crouching = animated_sprite.animation == ANIMATIONS.CROUCH


func _is_attack_animation() -> bool:
	return (
		animated_sprite.animation
		in [
			ANIMATIONS.ATTACK,
			ANIMATIONS.RUN_ATTACK,
		]
	)


# Input Handling
func _handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("JUMP"):
		is_jump_held = true
		if (is_on_floor() or has_coyote_time) and not is_jump_active:
			_handle_jump()
		else:
			if not is_jump_active:
				InputBuffer.buffer_jump()
	elif event.is_action_released("JUMP"):
		is_jump_held = false

	# Handle dash input
	if event.is_action_pressed("DASH") and can_dash and not is_dashing:
		state_machine.dispatch(&"dash")

	# Handle roll input
	if event.is_action_pressed("ROLL") and is_on_floor():
		state_machine.dispatch(&"roll")

	# Handle slide input
	if event.is_action_pressed("SLIDE") and abs(velocity.x) > 0:
		state_machine.dispatch(&"slide")

	if event.is_action_released("ATTACK"):
		if is_on_floor():
			if abs(velocity.x) > 0:  # If moving on ground
				if _has_enough_stamina(STATS.RUN_ATTACK_STAMINA_COST):
					_use_stamina(STATS.RUN_ATTACK_STAMINA_COST)
					state_machine.dispatch(&"run_attack")
			else:
				if _has_enough_stamina(STATS.ATTACK_STAMINA_COST):
					_use_stamina(STATS.ATTACK_STAMINA_COST)
					state_machine.dispatch(&"attack")
	elif event.is_action_released("CROUCH"):
		state_machine.dispatch(&"crouch")

	# Wall interactions
	if event.is_action_pressed("GRAB") and is_on_wall():
		_start_grab()
		state_machine.dispatch(&"wall_hang")
	elif event.is_action_released("GRAB"):
		_end_grab()

	# Health
	if event.is_action_released("HEALTH_DOWN"):
		take_damage(10.0)
	elif event.is_action_released("HEAL"):
		_heal(10.0)
	elif event.is_action_released("DIE"):
		take_damage(100.0)

	if event.is_action_pressed("level_up"):
		level_up_menu.show_menu()

	if event.is_action_pressed("interact") and current_merchant:
		if current_merchant.has_method("toggle_shop"):
			current_merchant.toggle_shop()


func _handle_jump() -> void:
	if (is_on_floor() or has_coyote_time) and not is_jump_active:
		velocity.y = jump_power
		is_jump_held = true
		is_jump_active = true
		has_coyote_time = false  # Consume coyote time
		coyote_timer = 0.0
		jump_timer.start()
		state_machine.dispatch(&"jump")  # Ensure we transition to jump state
		InputBuffer.consume_jump_buffer()  # Consume any buffered jump


# Override parent's die function
func _die() -> void:
	# Prevent multiple calls to _die() from happening at once
	if _is_death_transition_active:
		return

	_is_death_transition_active = true

	# Disable physics processing first
	state_machine.set_active(false)
	set_physics_process(false)

	# Store references to UI elements we need to hide
	var ui_elements = []
	if label and is_instance_valid(label):
		ui_elements.append(label)
	if health_bar and is_instance_valid(health_bar):
		ui_elements.append(health_bar)
	if stamina_bar and is_instance_valid(stamina_bar):
		ui_elements.append(stamina_bar)
	if xp_display and is_instance_valid(xp_display):
		ui_elements.append(xp_display)
	if level_up_menu and is_instance_valid(level_up_menu):
		ui_elements.append(level_up_menu)

	# Hide UI elements that are still valid
	for element in ui_elements:
		if is_instance_valid(element):
			element.hide()

	# Play death animation
	if animated_sprite and is_instance_valid(animated_sprite):
		animated_sprite.play(ANIMATIONS.DEATH)
		# Switch to the death shader material
		if _death_shader_material:
			animated_sprite.material = _death_shader_material

	# Screen Shake if camera is valid
	if camera and is_instance_valid(camera):
		camera.shake(10, 0.5, 0.9)

	# Death Sound
	SoundManager.play_sound(Sound.death, "SFX")

	# Start the fade effect
	is_fading = true
	fade_timer = 0.0

	# Get current inventory items before clearing
	var items = Inventory.get_items().duplicate(true)

	# Clear inventory
	Inventory.clear_inventory()

	# Determine bag spawn position based on floor status
	var spawn_position: Vector2
	if is_on_floor():
		spawn_position = global_position
	else:
		spawn_position = (last_floor_position if last_floor_position != Vector2.ZERO else global_position)

	# Adjust X position based on player direction
	if animated_sprite and is_instance_valid(animated_sprite):
		spawn_position.x += 20 if animated_sprite.flip_h else -20

	# Create and spawn bag with items if there are any
	if not items.is_empty():
		BagSpawner.spawn_bag(spawn_position, items)

	# Signal that player has died
	SignalBus.player_died.emit()

	# Create a timer for scene transition
	var transition_timer = Timer.new()
	get_tree().root.add_child(transition_timer)
	transition_timer.wait_time = 2.0
	transition_timer.one_shot = true
	transition_timer.timeout.connect(
		func():
			# Only proceed if we're not already transitioning
			if not SceneManager.is_transitioning:
				# Change to the game over scene
				(
					SceneManager
					. change_scene(
						"res://UI/Scenes/game_over.tscn",
						{
							"pattern_enter": "circle",
							"pattern_leave": "scribbles",
							"wait_time": 0.2,  # Quick transition
						}
					)
				)

			# Clean up timer
			transition_timer.queue_free()
	)
	transition_timer.start()

	# Start death timer after the transition timer
	if is_instance_valid(death_timer):
		death_timer.wait_time = 2.5  # Longer than transition timer
		death_timer.start()


func _on_death_timer_timeout() -> void:
	# Only clean up if we still exist
	if is_instance_valid(self):
		# Clean up physics before hiding/freeing
		_cleanup_physics_components()
		hide()
		# Reset flag (though not really needed since we're freeing)
		_is_death_transition_active = false
		# Queue free after scene transition
		queue_free()


# Magic System
func _handle_magic(healing_amount: float) -> void:
	if magic >= STATS.MAGIC_COST:
		health_manager.heal(healing_amount)
		magic = max(0, magic - STATS.MAGIC_COST)


# Take Damage
func take_damage(damage_amount: float) -> void:
	if is_invincible:
		return

	super.take_damage(damage_amount)
	current_health = health_manager.get_health()
	health_percent = health_manager.get_health_percentage()

	if current_health <= 0:
		_die()
	else:
		# Play hurt animation and sound
		animated_sprite.play(ANIMATIONS.HURT)

		SoundManager.set_sound_volume(0.4)

		SoundManager.play_sound(Sound.hurt, "SFX")

		# Enhanced screen shake with more impact
		camera.shake(12, 0.3, 0.85)

		# Damage pause effect
		Engine.time_scale = 0.05
		await get_tree().create_timer(0.35 * Engine.time_scale).timeout
		Engine.time_scale = 1.0

		# Start invincibility
		_start_invincibility()

		# Update health bar
		_update_health_bar()


# Health the health
func _heal(amount: float) -> void:
	super.heal(amount)
	current_health = health_manager.get_health()
	health_percent = health_manager.get_health_percentage()
	_update_health_bar()
	_check_health()


# Health regeneration
func _health_regen(delta: float) -> void:
	if current_health == max_health or not can_heal:
		return  # Exit

	current_health = min(current_health + health_regen_rate * delta, max_health)


# Check for health
func _check_health() -> void:
	if current_health == 0.0:
		_die()


# UI System
func _update_ui() -> void:
	label.text = ("Class: %s\nFPS: %s\nHealth: %s/%s (%.1f%%)\nStamina: %.1f/%s\nAnimation: %s" % ["None", Engine.get_frames_per_second(), current_health, max_health, health_percent, stamina, STATS.MAX_STAMINA, animated_sprite.animation])


func _connect_signals() -> void:
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	hurt_timer.timeout.connect(_on_hurt_timer_timeout)
	crouch_attack_timer.timeout.connect(_on_crouch_attack_timer_timeout)


# Signal Callbacks
func _on_attack_timer_timeout() -> void:
	state_machine.dispatch(&"state_ended")


func _on_crouch_attack_timer_timeout() -> void:
	state_machine.dispatch(&"crouch")


func _on_hurt_timer_timeout() -> void:
	state_machine.dispatch(&"state_ended")


func _on_time_taken_damage_timer_timeout() -> void:
	can_heal = true


func _jump_timer_timeout() -> void:
	is_jump_held = false
	is_jump_active = false
	velocity.y = 0


func _on_hit_landed(hitbox_node: Node, target_hurtbox: Node) -> void:
	# Only process hits from our own hitbox
	if hitbox_node.hitbox_owner != self:
		return

	if target_hurtbox.hurtbox_owner and target_hurtbox.hurtbox_owner.is_in_group("Enemy"):
		# Play hit effect or sound
		SoundManager.play_sound(Sound.hit, "SFX")
		# Apply lifesteal if enabled
		_apply_lifesteal(hitbox_node.damage)


func _on_hit_taken(attacker_hitbox: Node, defender_hurtbox: Node) -> void:
	# Only process hits to our own hurtbox
	if defender_hurtbox.hurtbox_owner != self:
		return

	if attacker_hitbox.hitbox_owner and attacker_hitbox.hitbox_owner.is_in_group("Enemy"):
		take_damage(attacker_hitbox.damage)


func _on_hurtbox_area_entered(_area: Area2D) -> void:
	pass  # Let hit_taken handle the damage


func _on_animation_changed() -> void:
	match animated_sprite.animation:
		ANIMATIONS.IDLE:
			animated_sprite.play(ANIMATIONS.IDLE)
		ANIMATIONS.RUN:
			animated_sprite.play(ANIMATIONS.RUN)
		ANIMATIONS.RUN_ATTACK:
			animated_sprite.play(ANIMATIONS.RUN_ATTACK)
		ANIMATIONS.CROUCH:
			animated_sprite.play(ANIMATIONS.CROUCH)
		ANIMATIONS.CROUCH_RUN:
			animated_sprite.play(ANIMATIONS.CROUCH_RUN)
		ANIMATIONS.JUMP:
			animated_sprite.play(ANIMATIONS.JUMP)
		ANIMATIONS.ATTACK:
			animated_sprite.play(ANIMATIONS.ATTACK)
		ANIMATIONS.DASH:
			animated_sprite.play(ANIMATIONS.DASH)
		ANIMATIONS.DEATH:
			animated_sprite.play(ANIMATIONS.DEATH)
		ANIMATIONS.FALL:
			animated_sprite.play(ANIMATIONS.FALL)
		ANIMATIONS.ROLL:
			animated_sprite.play(ANIMATIONS.ROLL)
		ANIMATIONS.SLIDE:
			animated_sprite.play(ANIMATIONS.SLIDE)
		ANIMATIONS.WALL_CLIMB:
			animated_sprite.play(ANIMATIONS.WALL_CLIMB)
		ANIMATIONS.WALL_HANG:
			animated_sprite.play(ANIMATIONS.WALL_HANG)


func _on_animation_finished() -> void:
	match animated_sprite.animation:
		ANIMATIONS.RUN:
			animated_sprite.play(ANIMATIONS.IDLE)
		ANIMATIONS.RUN_ATTACK:
			animated_sprite.play(ANIMATIONS.RUN)
		ANIMATIONS.JUMP:
			animated_sprite.play(ANIMATIONS.IDLE)
		ANIMATIONS.ATTACK:
			animated_sprite.play(ANIMATIONS.IDLE)
		ANIMATIONS.DASH:
			animated_sprite.play(ANIMATIONS.IDLE)
		ANIMATIONS.DEATH:
			# Death animation stays on last frame
			pass
		ANIMATIONS.ROLL:
			animated_sprite.play(ANIMATIONS.IDLE)
		ANIMATIONS.SLIDE:
			animated_sprite.play(ANIMATIONS.SLIDE)
		ANIMATIONS.WALL_CLIMB:
			animated_sprite.play(ANIMATIONS.WALL_HANG)


func _on_frame_changed() -> void:
	frame_data_component.update_frame_data()
	queue_redraw()


# Lifesteal System
func _apply_lifesteal(damage_dealt: float) -> void:
	var lifesteal_amount = damage_dealt * STATS.LIFESTEAL_PERCENT / 100.0
	lifesteal_amount = clamp(lifesteal_amount, STATS.MIN_LIFESTEAL_AMOUNT, STATS.MAX_LIFESTEAL_AMOUNT)

	if lifesteal_amount > 0:
		# Visual feedback for lifesteal
		_trigger_lifesteal_effect()
		# Play lifesteal sound
		SoundManager.play_sound(Sound.heal, "SFX")
		# Apply the healing
		_heal(lifesteal_amount)


# Visual feedback for lifesteal
func _trigger_lifesteal_effect() -> void:
	# Add a green flash or healing effect using the shader
	_shader_material.set_shader_parameter("lifesteal_active", true)
	await get_tree().create_timer(0.2).timeout
	_shader_material.set_shader_parameter("lifesteal_active", false)


func _on_health_changed(new_health: float, new_max_health: float) -> void:
	current_health = new_health
	max_health = new_max_health
	health_percent = health_manager.get_health_percentage()
	_update_health_bar()


func _on_character_died() -> void:
	_die()


func _on_attack_started(attacker: Node) -> void:
	# Only process if we are the attacker
	if attacker != self:
		return
	frame_data_component.update_frame_data()


func _on_attack_ended(attacker: Node) -> void:
	# Only process if we are the attacker
	if attacker != self:
		return
	frame_data_component.clear_active_boxes()


# Stamina System
func _stamina_regen(delta: float) -> void:
	if not is_attacking and not _is_running():
		stamina = min(stamina + STATS.STAMINA_REGEN_RATE * delta, STATS.MAX_STAMINA)


func _is_running() -> bool:
	return abs(velocity.x) > 0 and not is_crouching


func _update_stamina_bar() -> void:
	# Create a smooth tween for stamina bar updates
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(stamina_bar, "value", stamina, 0.3)

	# Dynamic color change based on stamina percentage
	var stamina_style = stamina_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if stamina_style:
		var stamina_percent = (stamina / STATS.MAX_STAMINA) * 100
		var new_color: Color
		if stamina_percent > 60:
			new_color = Color.from_string("#00cc66", Color.GREEN)  # Full stamina color
		elif stamina_percent > 30:
			new_color = Color.from_string("#ffcc00", Color.YELLOW)  # Medium stamina color
		else:
			new_color = Color.from_string("#ff6600", Color.ORANGE)  # Low stamina color

		# Tween the color change
		tween.parallel().tween_method(func(c): stamina_style.bg_color = c, stamina_style.bg_color, new_color, 0.3)

	# Pulse effect when stamina is low
	if stamina < STATS.MAX_STAMINA * 0.2:  # Less than 20% stamina
		var pulse_tween = create_tween()
		pulse_tween.set_loops()  # Make it loop
		pulse_tween.tween_property(stamina_bar, "modulate", Color(1.3, 1.3, 1.3, 1), 0.5)
		pulse_tween.tween_property(stamina_bar, "modulate", Color(1, 1, 1, 0.95), 0.5)

	# Flash effect when using a lot of stamina
	if stamina_bar.value - stamina > STATS.MAX_STAMINA * 0.3:  # Using more than 30% stamina
		var flash_tween = create_tween()
		flash_tween.tween_property(stamina_bar, "modulate", Color(1.5, 1.5, 1.5, 1), 0.1)
		flash_tween.tween_property(stamina_bar, "modulate", Color(1, 1, 1, 0.95), 0.2)


func _has_enough_stamina(cost: float) -> bool:
	return stamina >= cost


func _use_stamina(amount: float) -> void:
	stamina = max(0.0, stamina - amount)


# Save System
func _load_player_state(save_data: SaveData) -> void:
	# Only load position if we don't have a last bonfire position
	if save_data.last_bonfire_position == Vector2.ZERO:
		position = save_data.player_position
	else:
		position = save_data.last_bonfire_position

	current_health = save_data.current_health
	stamina = save_data.current_stamina
	magic = save_data.current_magic

	# Update UI
	_update_health_bar()
	_update_stamina_bar()
	_update_ui()


func save_player_state() -> void:
	save_engine.update_save_data(self)
	save_engine.save_game()


func respawn_at_bonfire() -> void:
	var bonfire_pos = save_engine.get_last_bonfire_position()
	if bonfire_pos != Vector2.ZERO:
		position = bonfire_pos
		_heal(max_health)  # Full heal on respawn
		stamina = STATS.MAX_STAMINA  # Full stamina on respawn
		magic = STATS.MAX_MAGIC  # Full magic on respawn


func _start_dash() -> void:
	is_dashing = true
	can_dash = false
	dash_timer = STATS.DASH_DURATION
	dash_cooldown_timer = STATS.DASH_COOLDOWN

	# Store dash direction
	dash_direction = -1.0 if animated_sprite.flip_h else 1.0

	# Apply immediate velocity for instant dash
	velocity.x = dash_direction * STATS.DASH_SPEED
	velocity.y = 0

	# Switch to dash shader material
	animated_sprite.material = _dash_shader_material

	# Play dash sound
	SoundManager.play_sound(Sound.dash, "SFX")

	# Enhanced screen shake for dash feedback
	camera.shake(8, 0.15, 0.8)

	# Brief pause for impact - even shorter now
	Engine.time_scale = 0.05
	await get_tree().create_timer(0.03).timeout  # Reduced from 0.05 to 0.03
	Engine.time_scale = 1.0

	# Switch back to normal shader after dash starts
	animated_sprite.material = _shader_material


# Add these methods to the player class
func get_max_health() -> float:
	return max_health


func get_max_stamina() -> float:
	return STATS.MAX_STAMINA


func restore_stamina(amount: float) -> void:
	stamina = min(stamina + amount, STATS.MAX_STAMINA)
	_update_stamina_bar()


func heal(amount: float) -> void:
	_heal(amount)  # Use existing heal method


func _start_invincibility() -> void:
	is_invincible = true
	invincibility_timer = 0.0
	animated_sprite.material = _invincibility_shader_material
	_invincibility_shader_material.set_shader_parameter("time_elapsed", 0.0)
	_invincibility_shader_material.set_shader_parameter("base_visible_duration", 0.2)
	_invincibility_shader_material.set_shader_parameter("base_invisible_duration", 0.1)
	_invincibility_shader_material.set_shader_parameter("duration_increase_rate", 0.001)
	hurtbox.start_invincibility(invincibility_duration)


func _end_invincibility() -> void:
	is_invincible = false
	invincibility_timer = 0.0
	animated_sprite.material = _shader_material
	hurtbox.end_invincibility()


# Silent version of heal that doesn't trigger effects
func _heal_silent(amount: float) -> void:
	if health_manager:
		health_manager.heal(amount)
		current_health = health_manager.get_health()
		health_percent = health_manager.get_health_percentage()
		_update_health_bar()
		_check_health()


# Add this function near other healing-related functions
func use_celestial_tear() -> void:
	# Heal to full health silently
	var H = get_max_health()
	_heal_silent(H)

	# Restore stamina to full
	var S = get_max_stamina()
	restore_stamina(S)

	# Play heal sound when using the tear
	SoundManager.play_sound(Sound.heal, "SFX")


# Add this function near other healing-related functions
func _on_item_used(item_data: Dictionary) -> void:
	if item_data.id == "celestial_tear":
		use_celestial_tear()


# Add these new methods
func _start_grab() -> void:
	if grab_collision_shape and is_on_wall() and _has_enough_stamina(STATS.WALL_CLIMB_STAMINA_DRAIN * 0.1):
		grab_collision_shape.disabled = false
		is_grabbing = true
		# Apply upward movement while grabbing
		velocity.y = STATS.WALL_CLIMB_SPEED
		# Use stamina
		_use_stamina(STATS.WALL_CLIMB_STAMINA_DRAIN * get_physics_process_delta_time())


func _end_grab() -> void:
	if grab_collision_shape:
		grab_collision_shape.disabled = true
		is_grabbing = false
		state_machine.dispatch(&"state_ended")


# Modify the wall_hang_update function to check for ledge climbing
func _update_wall_climbing(delta: float) -> void:
	if is_grabbing and not is_ledge_climbing:
		if is_on_wall() and _has_enough_stamina(STATS.WALL_CLIMB_STAMINA_DRAIN * delta):
			velocity.y = STATS.WALL_CLIMB_SPEED
			_use_stamina(STATS.WALL_CLIMB_STAMINA_DRAIN * delta)
			animated_sprite.play(ANIMATIONS.WALL_CLIMB)

			# Check if we can climb the ledge
			if _can_climb_ledge():
				_start_ledge_climb()
		else:
			_end_grab()  # Let go if not on wall or out of stamina


# Modify the _can_climb_ledge function
func _can_climb_ledge() -> bool:
	if !ledge_check or is_ledge_climbing:
		return false

	# Update raycast direction based on character facing
	var check_direction = -1 if animated_sprite.flip_h else 1
	ledge_check.target_position.x = 32 * check_direction

	# Force the raycast to update
	ledge_check.force_raycast_update()

	# Check if we found a valid ledge
	return ledge_check.is_colliding() and not ledge_check.get_collision_point().is_equal_approx(global_position)


# Update the ledge climb function
func _start_ledge_climb() -> void:
	if !ledge_climb_position or is_ledge_climbing:
		return

	is_ledge_climbing = true

	# Disable physics and stop all movement
	set_physics_process(false)
	velocity = Vector2.ZERO

	# Update marker position based on character facing
	var climb_offset = Vector2(24, -24)
	if animated_sprite.flip_h:
		climb_offset.x *= -1

	# Calculate the target position based on the raycast collision
	var target_position = Vector2.ZERO
	if ledge_check.is_colliding():
		var collision_point = ledge_check.get_collision_point()
		target_position = Vector2(collision_point.x - (climb_offset.x / 2 * (-1 if animated_sprite.flip_h else 1)), collision_point.y + climb_offset.y)

	# Create a tween for smooth movement
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	# First move up to the ledge height
	var intermediate_pos = Vector2(global_position.x, target_position.y)
	tween.tween_property(self, "global_position", intermediate_pos, 0.3)

	# Then move onto the platform
	tween.tween_property(self, "global_position", target_position, 0.2)

	# When the climb is complete
	tween.tween_callback(
		func():
			is_ledge_climbing = false
			set_physics_process(true)
			state_machine.dispatch(&"state_ended")
	)


# Add this function near the end of the file
func _setup_ui_displays() -> void:
	# Load UI scenes
	var xp_display_scene = load("res://UI/Scenes/xp_display.tscn")
	var level_up_menu_scene = load("res://UI/Scenes/level_up_menu.tscn")

	if xp_display_scene and level_up_menu_scene:
		# Add souls display
		var souls_display_scene = load("res://UI/Scenes/souls_display.tscn")
		if souls_display_scene:
			var souls_display = souls_display_scene.instantiate()
			ui_layer.add_child(souls_display)

			# Position souls display on the right side
			souls_display.position = Vector2(get_viewport_rect().size.x - souls_display.size.x - 20, 20)  # 20 pixels from right edge  # 20 pixels from top

			# Add XP display
			xp_display = xp_display_scene.instantiate()
			ui_layer.add_child(xp_display)

			# Position XP display below souls display
			xp_display.position = Vector2(get_viewport_rect().size.x - xp_display.size.x - 20, souls_display.position.y + souls_display.size.y + 10)  # 20 pixels from right edge  # 10 pixels below souls display

			# Add level up menu
			level_up_menu = level_up_menu_scene.instantiate()
			ui_layer.add_child(level_up_menu)
			level_up_menu.hide()  # Start hidden


func set_gravity_enabled(enabled: bool) -> void:
	gravity_enabled = enabled


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and current_merchant:
		if current_merchant.has_method("toggle_shop"):
			current_merchant.toggle_shop()


func _on_chat_box_area_entered(area: Area2D) -> void:
	if area.get_parent().is_in_group("Merchant"):
		current_merchant = area.get_parent()


func _on_chat_box_area_exited(area: Area2D) -> void:
	if area.get_parent() == current_merchant:
		current_merchant = null


# Add new function to handle physics cleanup
func _cleanup_physics_components() -> void:
	# First, remove all collision shapes from their parents
	for child in get_children():
		if child is CollisionShape2D:
			remove_child(child)
			child.queue_free()
		elif child is CollisionPolygon2D:
			remove_child(child)
			child.queue_free()

	# Disable and clean up grab collision shape
	if grab_collision_shape:
		grab_collision_shape.set_deferred("disabled", true)
		if grab_collision_shape.get_parent():
			grab_collision_shape.get_parent().remove_child(grab_collision_shape)
			grab_collision_shape.queue_free()

	# Clean up hitbox
	if hitbox:
		hitbox.active = false
		hitbox.collision_layer = 0
		hitbox.collision_mask = 0
		hitbox.set_deferred("monitoring", false)
		hitbox.set_deferred("monitorable", false)
		# Clean up hitbox's collision shapes
		for child in hitbox.get_children():
			if child is CollisionShape2D or child is CollisionPolygon2D:
				hitbox.remove_child(child)
				child.queue_free()
		if hitbox.get_parent():
			hitbox.get_parent().remove_child(hitbox)
			hitbox.queue_free()

	# Clean up hurtbox
	if hurtbox:
		hurtbox.active = false
		hurtbox.collision_layer = 0
		hurtbox.collision_mask = 0
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)
		# Clean up hurtbox's collision shapes
		for child in hurtbox.get_children():
			if child is CollisionShape2D or child is CollisionPolygon2D:
				hurtbox.remove_child(child)
				child.queue_free()
		if hurtbox.get_parent():
			hurtbox.get_parent().remove_child(hurtbox)
			hurtbox.queue_free()

	# Disable and clean up ledge check
	if ledge_check:
		ledge_check.enabled = false
		if ledge_check.get_parent():
			ledge_check.get_parent().remove_child(ledge_check)
			ledge_check.queue_free()

	# Clear collision layers and masks
	collision_layer = 0
	collision_mask = 0

	# Disable physics process
	set_physics_process(false)
	set_process_input(false)

	# Clear any remaining physics state
	velocity = Vector2.ZERO
	is_grabbing = false
	is_dashing = false
	is_ledge_climbing = false
	gravity_enabled = false

	# Call queue_free on self after a short delay to ensure cleanup
	await get_tree().create_timer(0.1).timeout
	queue_free()
