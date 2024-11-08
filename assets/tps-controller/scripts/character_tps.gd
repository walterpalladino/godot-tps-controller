extends CharacterBody3D

@onready var collision_shape = get_node("CollisionShape3D")
@onready var animation_tree : AnimationTree = get_node("AnimationTree")

@onready var model = get_node("Model")

@export_category("Ground Movement")

@export var walk_speed = 2.0
@export var run_speed = 4.50
@export var crouch_speed = 1.0

var running : bool = false
var crouch : bool = false

var movement : Vector2 = Vector2.ZERO

var last_turning_value : float = 0

@export_category("On AIr")

@export var gravity = 9.81
@export var jump_height : float = 2.0
@export var min_time_between_jumps = 1.0 # in seconds
var last_jump_time : float = 0


@export_category("Camera Follow")

@export var lookAt : Node3D
var lastLookAtDirection : Vector3
@export var turn_speed = .05

@export var mouse_sensitivity : float = 2

@onready var camera_mount : Node3D = get_node("CameraMount")

# Get the gravity from the project settings to be synced with RigidBody nodes.
#var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


const STEP_RAY_LENGTH = 0.2


# steps
@export_category("Steps")
@export var max_step_height : float = 0.40

@export var step_max_slope_degree : float = 40.0

var is_step : bool = false
var is_step_up : bool = false	# true: step up false : step down
var step_diff_position : Vector3 = Vector3.ZERO



var on_walkable_slope : bool = false
var surface_angle : float = 0.0

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
		
		#print_debug(camera_mount.rotation.x)
		
		


func _physics_process(delta):

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	movement = Vector2(input_dir.x, -input_dir.y)

	if is_on_floor():
		is_jumping = false
		is_in_air = false
	else:
		is_in_air = true

	if Input.is_action_just_pressed("move_crouch_stand"):
		crouch = !crouch 

	if crouch:
		running = false
	else:
		running = Input.is_action_pressed("move_run")

	var new_velocity = Vector3.ZERO
	var movement_speed = walk_speed if (!running) else run_speed 
	movement_speed = crouch_speed if crouch else movement_speed
	
	if direction:
		new_velocity.x = direction.x * movement_speed
		new_velocity.z = direction.z * movement_speed
	else:
		new_velocity.x = move_toward(velocity.x, 0, movement_speed)
		new_velocity.z = move_toward(velocity.z, 0, movement_speed)
	
	is_step = check_step(delta, new_velocity)

	# Handle Jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
	if is_on_floor():

		if Input.is_action_just_pressed("move_jump") and Time.get_ticks_msec() > last_jump_time + min_time_between_jumps * 1000.0:
			is_jumping = true
			is_in_air = false
			new_velocity.y = calculate_jump_vertical_speed()
			last_jump_time = Time.get_ticks_msec()

	if is_step:
		global_transform.origin += step_diff_position

	# Add the gravity.
	if not is_on_floor() :
		new_velocity.y = velocity.y - gravity * delta
	else:
		if (new_velocity.y < 0.0):
			new_velocity.y = -0.1
				
	velocity = new_velocity
	move_and_slide()
	
	update_animations(delta, input_dir)

	if is_jumping :
		is_jumping = false
		is_in_air = true



func check_step(delta:float, main_velocity:Vector3):
	
	is_step = false
	is_step_up = false
	step_diff_position = Vector3.ZERO
	
	# do not check if character is idle in case try to jump to avoid detecting collissions with nearby walls
	if (main_velocity.length() == 0):
		return false
	
	var test_motion_result: PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()
	var transform3d: Transform3D = global_transform
	var motion: Vector3 = main_velocity * delta
	
	# test first if can horizontally move
	var test_motion_params: PhysicsTestMotionParameters3D = PhysicsTestMotionParameters3D.new()
	test_motion_params.from = transform3d
	test_motion_params.motion = motion
	test_motion_params.recovery_as_collision = true

	var is_player_collided: bool = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
	
	# check if hits something up that can not be a step and return
	if is_player_collided and test_motion_result.get_collision_normal().y < 0:
		return false
	
	# check if there is a step ahead
	# can move at step height
	transform3d.origin += Vector3.UP * (max_step_height - 0.05)
	motion = main_velocity * delta
	test_motion_params.from = transform3d
	test_motion_params.motion = motion
	
	is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
			
	# collided at step height with a wall or step higher than allowed
	if (is_player_collided):
		pass
		
	# havent collided with nothing at higher than step height
	if not is_player_collided:

		transform3d.origin += motion #- Vector3.UP * 0.05
		
		# check any step up to maximum height
		motion = - Vector3.UP * max_step_height
		test_motion_params.from = transform3d
		test_motion_params.motion = motion
		
		is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
		
		# found a step
		if is_player_collided:

			if test_motion_result.get_collision_normal().angle_to(Vector3.UP) >= deg_to_rad(step_max_slope_degree):
				is_step = true
				is_step_up = true
				step_diff_position = -test_motion_result.get_remainder()
				return true
		else:
			# no step up ahead
			# check for step down
			transform3d.origin += motion
			motion = - Vector3.UP * max_step_height
			test_motion_params.from = transform3d
			test_motion_params.motion = motion
				
			is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
			if is_player_collided and test_motion_result.get_travel().y < max_step_height:
				if test_motion_result.get_collision_normal().angle_to(Vector3.UP) >= deg_to_rad(step_max_slope_degree):
					is_step = true
					is_step_up = false
					step_diff_position = test_motion_result.get_travel()
					return true

	return false

		
func check_distance_to_floor():
	var space_state = get_world_3d().direct_space_state
	
	var origin : Vector3 = transform.origin + Vector3.UP * 0.05
	var end = origin + Vector3.DOWN * 100.0
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true

	var result = space_state.intersect_ray(query)
	if !result:
		return 100.0
	else:
		return clamp(transform.origin.y - result.position.y, 0.0, 100.0)
						


# Update animations
func update_animations(delta, input_dir):

	#	calculate turning value when character turn when idle
	var turning = (Input.get_last_mouse_velocity().x / 1000 * mouse_sensitivity)
	turning = clamp(turning, -1.0, 1.0)
	turning = lerp(last_turning_value, turning, delta * 25.0)
	last_turning_value = turning

	var is_idle : bool = input_dir.x == 0.0 && (is_on_floor() || is_step)
	var is_walking : bool = velocity.x != 0.0 && (is_on_floor() || is_step)
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
			animation_tree.set("parameters/crouch_blend/blend_position", movement)
		else:
		
			if is_idle:
				animation_tree.set("parameters/State/transition_request", "idle_state")
				animation_tree.set("parameters/in_place_blend/blend_position", turning)
			if is_running:
				animation_tree.set("parameters/State/transition_request", "running_state")
				animation_tree.set("parameters/run_blend/blend_position", movement)
				print_debug(movement)
			elif is_walking:
				animation_tree.set("parameters/State/transition_request", "walking_state")
				animation_tree.set("parameters/walk_blend/blend_position", movement)
				print_debug(movement)
		
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



func add_action_key(action, key_code):
	
	if InputMap.has_action(action):
		InputMap.erase_action(action)

	InputMap.add_action(action)
	var event
	event = InputEventKey.new()
	event.keycode = key_code
	InputMap.action_add_event(action, event)
	
	print_debug(InputMap.get_actions())
