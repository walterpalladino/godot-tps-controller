extends CharacterController3D

@onready var collision_shape = get_node("CollisionShape3D")
@onready var animation_tree : AnimationTree = get_node("AnimationTree")

@onready var model = get_node("Model")

@export_category("Ground Movement")

@export var walk_speed = 2.0
@export var run_speed = 6.0
@export var crouch_speed = 1.0
@export var speed_change = 5.0

var walking : bool = false
var running : bool = false
var crouch : bool = false

var movement : Vector2 = Vector2.ZERO

var last_turning_value : float = 0.0
var last_speed : float = 0.0

@export_category("On AIr")

@export var gravity = 9.81
@export var jump_height : float = 2.0
@export var min_time_between_jumps = 1.0 # in seconds
var last_jump_time : float = 0

@export var max_height_normal_fall : float = 2.0
var last_on_floor_height : float = 0.0


@export_category("Camera Follow")

@export var lookAt : Node3D
var lastLookAtDirection : Vector3
@export var turn_speed = .05

@export var mouse_sensitivity : float = 2

@onready var camera_mount : Node3D = get_node("CameraMount")

# Get the gravity from the project settings to be synced with RigidBody nodes.
#var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


const STEP_RAY_LENGTH = 0.2


var on_floor : bool = false

var is_jumping: bool = false
var is_in_air: bool = false

var last_face_direction : float = 1



func _ready() -> void:

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	setup_input()


func _input(event: InputEvent) -> void:
	
	if event is InputEventMouseMotion:
		#	rotate the player
		rotate_y( -event.relative.x / 1000 * mouse_sensitivity )

		#	rotate the camera around its pivot
		#	clamp the value
		var temp_rot = camera_mount.rotation.x - event.relative.y / 1000 * mouse_sensitivity
		temp_rot = clamp(temp_rot, -0.8, 1.0) # -1, 0.25
		camera_mount.rotation.x = temp_rot
		
		# to avoid model turning with camera
		# model will only turn when moves
		model.rotate_y(event.relative.x / 1000 * mouse_sensitivity)
		#print_debug(camera_mount.rotation.x)
		
	if event is InputEventMouseButton:
		if not Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		
	if event is InputEventKey:
		if event.is_released():
			if event.keycode == KEY_ESCAPE:
			#  if event.is_action_pressed("ui_cancel"):
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta):

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	movement = Vector2(input_dir.x, -input_dir.y)
	

	if is_on_floor():
		is_jumping = false
		is_in_air = false
		
		var delta_fall : float = last_on_floor_height - global_position.y
		if delta_fall > max_height_normal_fall:
			print_debug("hard fall") 
	else:
		is_in_air = true

	if Input.is_action_just_pressed("move_crouch_stand"):
		crouch = !crouch 

	if crouch:
		walking = false
		running = false
	else:
		running = Input.is_action_pressed("move_run")

	var new_velocity = Vector3.ZERO
	var speed : float = 0.0
	if crouch:
		speed = crouch_speed
	else:
		if running:
			speed = run_speed
		else:
			speed = walk_speed
	if not direction:
		speed = 0.0
	speed = lerp(last_speed, speed, delta * speed_change)
	last_speed = speed

	new_velocity.x = direction.x * speed
	new_velocity.z = direction.z * speed
	
	#if direction:
	#	new_velocity.x = direction.x * speed
	#	new_velocity.z = direction.z * speed
	#else:
	#	new_velocity.x = move_toward(velocity.x, 0, speed)
	#	new_velocity.z = move_toward(velocity.z, 0, speed)
	
	check_step(delta, new_velocity)

	# Handle Jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
	if is_on_floor():

		if Input.is_action_just_pressed("move_jump") and Time.get_ticks_msec() > last_jump_time + min_time_between_jumps * 1000.0:
			is_jumping = true
			is_in_air = false
			new_velocity.y = calculate_jump_vertical_speed()
			last_jump_time = Time.get_ticks_msec()

	#if is_step:
	#	global_transform.origin += step_diff_position

	# Add the gravity.
	if not is_on_floor() :
		new_velocity.y = velocity.y - gravity * delta
	else:
		if (new_velocity.y < 0.0):
			new_velocity.y = -0.1
				
	velocity = new_velocity
	move_and_slide()
	
	update_model_facing(delta, new_velocity.normalized())
	update_animations()

	if is_jumping :
		is_jumping = false
		is_in_air = true

	if not is_in_air:
		last_on_floor_height = global_position.y


func update_model_facing(delta : float, direction : Vector3):

	if Vector2(direction.x, direction.z).length() != 0.0:

		# no interpolation
		#var target_position : Vector3 = model.global_position + Vector3(direction.x, 0, direction.z)
		#model.look_at(target_position)

		#model.global_rotation.y = atan2(direction.normalized().x, direction.normalized().z) + PI
		model.global_rotation.y = lerp_angle( model.global_rotation.y, atan2(direction.normalized().x, direction.normalized().z) + PI, delta * 10.0 )





# Update animations
func update_animations():

	#print_debug(last_speed)
	var is_idle : bool = last_speed == 0.0 && (is_on_floor() || is_step)
	var is_walking : bool = last_speed != 0.0 && (is_on_floor() || is_step)
	var is_running : bool = is_walking and running

	var is_crouched : bool = crouch && (is_on_floor() || is_step)

	
	#	Check distance to floor
	var distance_to_floor : float  = check_distance_to_floor()
	if is_on_floor() || is_step:
		distance_to_floor = 0.0
	#print_debug(distance_to_floor)

	var is_grounded : bool = (is_on_floor() || is_step) || (distance_to_floor <= max_step_height)


	#print_debug(animation_tree.get("parameters/State/current_state"))

	if !is_grounded:
		animation_tree.set("parameters/State/transition_request", "on_air_state")
	else:
		
		if is_crouched:
			animation_tree.set("parameters/State/transition_request", "crouch_state")
			animation_tree.set("parameters/crouch_movement_blend/blend_position", last_speed)
		else:
		
			if is_idle:
				animation_tree.set("parameters/State/transition_request", "idle_state")
			if is_running:
				animation_tree.set("parameters/State/transition_request", "running_state")
				animation_tree.set("parameters/run_movement_blend/blend_position", last_speed)
			elif is_walking:
				animation_tree.set("parameters/State/transition_request", "walking_state")
				animation_tree.set("parameters/walk_movement_blend/blend_position", last_speed)
		
	#animation_tree.set("parameters/State/transition_request", "on_air_state")

		
func calculate_jump_vertical_speed():
	return sqrt(2.0 * gravity * jump_height)

#	Setup used inputs
func setup_input():
	
	add_action_key("move_left", KEY_A)
	add_action_key("move_right", KEY_D)
	add_action_key("move_forward", KEY_W)
	add_action_key("move_backward", KEY_S)

	add_action_key("move_jump", KEY_SPACE)

	add_action_key("move_crouch_stand", KEY_C)

	add_action_key("move_run", KEY_SHIFT)

	print_debug(InputMap.get_actions())
