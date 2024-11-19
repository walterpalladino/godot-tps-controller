extends CharacterController3D

@onready var collision_shape = get_node("CollisionShape3D")
@onready var animation_tree : AnimationTree = get_node("AnimationTree")
@onready var state_machine := animation_tree.get("parameters/side_scroller_sm/playback") as AnimationNodeStateMachinePlayback

@onready var model = get_node("Model")


@export_category("Ground Movement")

@export var walk_speed = 2.0
@export var run_speed = 6.0
@export var crouch_speed = 1.0
@export var speed_change = 5.0

var walking : bool = false
var running : bool = false
var crouch : bool = false


@export_category("On AIr")

@export var gravity = 9.81
@export var jump_height : float = 2.0
@export var min_time_between_jumps = 1.0 # in seconds
var last_jump_time : float = 0.0
var last_y_in_floor : float = 0.0



const STEP_RAY_LENGTH = 0.2




var on_floor : bool = false

var is_jumping: bool = false
var is_in_air: bool = false
var was_on_air : bool = false

var last_face_direction : float = 1


	

func _ready() -> void:

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	setup_input()
	


func _input(event: InputEvent) -> void:
		
	if event is InputEventMouseButton:
		if not Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
	if event is InputEventKey:
		if event.is_released():
			if event.keycode == KEY_ESCAPE:
			#  if event.is_action_pressed("ui_cancel"):
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta):
	
	if is_blocking_animation_running():
		return
		
	update_character(delta)



func update_character(delta):
	
	if is_on_floor():
		if is_in_air:
			was_on_air = true
		is_jumping = false
		is_in_air = false
	else:
		is_in_air = true
		
		
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = Vector3.RIGHT * sign(input_dir.x) 
	var jump : bool = input_dir.y < 0.0

	#	evaluate movement velocity
	var new_velocity = Vector3.ZERO
	if direction:
		new_velocity.x = direction.x * walk_speed
		new_velocity.z = 0 # No lateral movement - to and from screen
	else:
		new_velocity.x = move_toward(new_velocity.x, 0, walk_speed)
		new_velocity.z = 0 # No lateral movement - to and from screen


	# Handle Jump.
	if is_on_floor():

		if jump and Time.get_ticks_msec() > last_jump_time + min_time_between_jumps * 1000.0:
			is_jumping = true
			is_in_air = false
			new_velocity.y = calculate_jump_vertical_speed()
			last_jump_time = Time.get_ticks_msec()

		elif (new_velocity.y < 0.0):
			new_velocity.y = -0.1
	else:
		# Add the gravity.
		new_velocity.y = velocity.y - gravity * delta
		
		if transform.origin.y > last_y_in_floor:
			last_y_in_floor = transform.origin.y

	
	velocity = new_velocity

	check_step_move_and_slide()
	
	update_model_facing()
	update_animations()

	if is_jumping :
		is_jumping = false
		is_in_air = true


func update_model_facing():
	
	if velocity.x != 0.0:
		var facing_angle : float = sign(velocity.x) * 90.0
		#var face_direction = Vector3( 0.0, facing_angle, 0.0)
		#model.set_rotation_degrees(face_direction)
		model.global_rotation.y = lerp_angle( model.global_rotation.y, deg_to_rad(facing_angle), get_physics_process_delta_time() * 10.0 )
		last_face_direction = sign(velocity.x)



# Update animations
func update_animations():

	var is_idle : bool = velocity.x == 0.0 && (is_on_floor() || is_step)
	var is_walking : bool = velocity.x != 0.0 && (is_on_floor() || is_step)
	var is_running : bool = is_walking and running

	var is_crouched : bool = crouch && (is_on_floor() || is_step)

	#	Check distance to floor
	var distance_to_floor : float  = check_distance_to_floor()
	if is_on_floor() || is_step:
		distance_to_floor = 0.0
	#print_debug(distance_to_floor)

	var is_grounded : bool = (is_on_floor() || is_step) 
	if velocity.y <= 0:
		is_grounded = is_grounded || (distance_to_floor <= 1.5 * max_step_height)
		
	if !is_grounded:
		animation_tree.set("parameters/State/transition_request", "on_air_state")
	else:
		if was_on_air:
			was_on_air = false
			
			animation_tree.set("parameters/landed/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
				
			last_y_in_floor = transform.origin.y
		elif is_crouched:
			animation_tree.set("parameters/State/transition_request", "crouch_state")
		else:
	
			if is_idle:
				animation_tree.set("parameters/State/transition_request", "idle_state")
			if is_running:
				animation_tree.set("parameters/State/transition_request", "running_state")
			elif is_walking:
				animation_tree.set("parameters/State/transition_request", "walking_state")


#	add here any animation that should be tested to block
#	the cahracter interaction
func is_blocking_animation_running():
	
	if animation_tree.get("parameters/landed/active"):
		return true
	
	return false


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
