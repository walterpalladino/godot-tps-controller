@icon("res://assets/x-controller/CharacterBody3D-X.svg")

extends CharacterController3D

#	character_side_action_controller

enum CONTROLLER_STATE {LOCOMOTION, ON_AIR, CLIMBING}


@onready var collision_shape = get_node("CollisionShape3D")
@onready var animation_tree : AnimationTree = get_node("AnimationTree")
@onready var model = get_node("Model")


@export_category("Ground Movement")

@export var max_character_speed_ground = 6.0
@export var max_character_speed_crouched = 2.0
#@export var speed_change = 50.0
#@export var crouch_speed = 2.0

var is_crouched : bool = false


@export_category("On AIr")
## Lapse in mili seconds
@export var max_character_speed_on_air = 6.0
@export var reaction_character_speed_on_air = 1.0
@export var min_time_between_jumps : float = 1.0 # in seconds
var last_jump_time : float = 0.0
var last_y_in_floor : float = 0.0


var was_on_air : bool = false


@export_category("Wall Movement")
@export var climbing_speed : float = 1

var was_climbing : bool = false
var climbing_leaving_from_top : bool = false
#	offset used to adjust end of climbing to top animation
@export var climbing_leaving_from_top_offset : Vector3 = Vector3(-0.50, 1.35, 0.0)

var last_face_direction : float = 1


var controller_state : CONTROLLER_STATE = CONTROLLER_STATE.ON_AIR


var rifle_enabled : bool = false


#-----------------------------------------------------
func _ready() -> void:

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	setup_input()
	


#-----------------------------------------------------
func _input(event: InputEvent) -> void:
		
	if event is InputEventMouseButton:
		if not Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
	if event is InputEventKey:
		if event.is_released():
			if event.keycode == KEY_ESCAPE:
			#  if event.is_action_pressed("ui_cancel"):
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


#-----------------------------------------------------
func _physics_process(delta):

	if is_blocking_animation_running():
		return

	update_character(delta)


#-----------------------------------------------------
func update_character(delta):
	
	
	update_weapons()
	
	
	match controller_state:
		CONTROLLER_STATE.LOCOMOTION:
			update_character_locomotion(delta)
		CONTROLLER_STATE.ON_AIR:
			update_character_on_air(delta)
		CONTROLLER_STATE.CLIMBING:
			update_character_climbing(delta)
		


func update_weapons():
	
	if Input.is_action_just_pressed("rifle_enabled") :
		
		rifle_enabled = !rifle_enabled
		
		if rifle_enabled:
			animation_tree.set("parameters/Armed/transition_request", "rifle_state")
		else:
			animation_tree.set("parameters/Armed/transition_request", "unarmed_state")



#-----------------------------------------------------
func update_character_on_air(delta):
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

	#	hit ground?
	if is_on_floor():
		was_on_air = true
		controller_state = CONTROLLER_STATE.LOCOMOTION
		return

	if is_on_wall() and input_dir.y < 0.0:
		
		if check_can_climb_wall(get_facing_direction()):
			#print_debug("Now is climbing a wall")
			was_climbing = false
			controller_state = CONTROLLER_STATE.CLIMBING
			return


	var new_velocity = Vector3.ZERO
	new_velocity.x = velocity.x
	
	#	If being on air and no horizontal move
	#	the character tries to move, will only be able to do that
	#	on the actual facing direction at a very #	small speed
	#	but enough to climb high steps 
	if new_velocity.x == 0:
		if sign(input_dir.x) == last_face_direction:
			new_velocity.x = sign(input_dir.x) * reaction_character_speed_on_air
	
	
	#	add the gravity.
	new_velocity.y = velocity.y - gravity * delta
		
	if transform.origin.y > last_y_in_floor:
		last_y_in_floor = transform.origin.y
	
	velocity = new_velocity

	move_and_slide()
	
	update_model_facing()
	update_animations()


	
#-----------------------------------------------------	
func update_character_climbing(delta):
	
	if climbing_leaving_from_top:
		
		climbing_leaving_from_top = false
		is_crouched = true
		
		var offset : Vector3 = climbing_leaving_from_top_offset
		offset.x *= -sign(last_face_direction)
		global_transform.origin += offset

		controller_state = CONTROLLER_STATE.LOCOMOTION
		
		velocity = Vector3.ZERO
		move_and_slide()
		
		return
	
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	#	leaving from the ground
	if is_on_floor() and input_dir.y > 0.0:
		#print_debug("Was climbing")
		was_climbing = true
		controller_state = CONTROLLER_STATE.LOCOMOTION
		return

	#	jumps away the wall
	if input_dir.x != 0:
		velocity.x = 6.0 * sign(input_dir.x)
		velocity.y = 2.0
		move_and_slide()
		was_climbing = true
		controller_state = CONTROLLER_STATE.ON_AIR
		return

	if !check_can_climb_wall(get_facing_direction()):
		
		if wall_collision_result == (WALL_COLLISION_RESULT.COLLISION_MID | WALL_COLLISION_RESULT.COLLISION_BOTTOM):
			#	climbing to the top
			climbing_leaving_from_top = true
			update_animations()
			return
		else:
			# nothing to hold on to...
			move_and_slide()
			was_climbing = true
			controller_state = CONTROLLER_STATE.ON_AIR
			return


	#var facing_direction : Vector3 = Vector3(sign(last_face_direction), 0.0, 0.0)

	var new_velocity : Vector3 = Vector3.ZERO
	new_velocity.y = climbing_speed * -input_dir.y
	
	velocity = new_velocity
	move_and_slide()
	
	update_animations()


#-----------------------------------------------------
func update_character_locomotion(delta):
	
	if !is_grounded() :
		controller_state = CONTROLLER_STATE.ON_AIR
		return

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

	if is_on_wall() and input_dir.y < 0.0:

		if check_can_climb_wall(get_facing_direction()):
			was_climbing = false
			controller_state = CONTROLLER_STATE.CLIMBING
			return

	
	# Get the input direction and handle the movement/deceleration.
	var direction = Vector3.RIGHT * sign(input_dir.x) 

	
#	if (velocity.x < max_character_speed * 0.5) && (Input.is_action_just_pressed("move_crouch_stand") || Input.is_action_just_pressed("move_backward")):
	if velocity.x <= max_character_speed_crouched :
		if Input.is_action_just_pressed("move_crouch_stand") || Input.is_action_just_pressed("move_backward"):
			is_crouched = !is_crouched 
			
	var jump : bool = (input_dir.y < 0.0) #and !is_crouched 


	#	evaluate movement velocity
	var new_velocity = Vector3.ZERO
	var target_speed = 0.0	# depends on if the target is stand or crouched 
	
	if direction.x != 0.0:
		if is_crouched:
			target_speed = max_character_speed_crouched
		else:
			target_speed = max_character_speed_ground
	
	new_velocity.x = target_speed * sign(direction.x) #lerp(abs(velocity.x), target_speed, speed_change * delta) * sign(direction.x)
	new_velocity.z = 0 # No lateral movement - to and from screen
	
		
	# Handle Jump.
	if jump and Time.get_ticks_msec() > last_jump_time + min_time_between_jumps * 1000.0:

		is_crouched = false
		
		new_velocity.x = max_character_speed_on_air * sign(direction.x)
		new_velocity.y = calculate_jump_vertical_speed()

		last_jump_time = Time.get_ticks_msec()
		
		velocity = new_velocity
		move_and_slide()

		controller_state = CONTROLLER_STATE.ON_AIR
		
		return

	elif (new_velocity.y < 0.0):
		#	add a bit to keep the character grounded
		new_velocity.y = -0.1

	
	velocity = new_velocity
	check_step_move_and_slide()
	
	update_model_facing()
	update_animations()


func get_facing_direction():
	return 	Vector3(sign(last_face_direction), 0.0, 0.0)

		
#-----------------------------------------------------
func update_model_facing():
	
	var facing_angle : float = sign(last_face_direction) * 90.0
	model.global_rotation.y = lerp_angle( model.global_rotation.y, deg_to_rad(facing_angle), get_physics_process_delta_time() * 10.0 )
	if velocity.x != 0.0:
		last_face_direction = sign(velocity.x)


#-----------------------------------------------------
# Update animations
func update_animations():

	match controller_state:
		CONTROLLER_STATE.LOCOMOTION:
			animate_locomotion()
		CONTROLLER_STATE.ON_AIR:
			animate_on_air()
		CONTROLLER_STATE.CLIMBING:
			animate_climbing()




#-----------------------------------------------------
func animate_locomotion():

	if was_on_air:

		#	Set to be sure the transsition after the one shot is locomotion
		if rifle_enabled:
			animation_tree.set("parameters/RifleLocomotion/blend_position", abs(velocity.x) / max_character_speed_ground)
			animation_tree.set("parameters/RifleState/transition_request", "locomotion_state")
		else:
			animation_tree.set("parameters/Locomotion/blend_position", abs(velocity.x) / max_character_speed_ground)
			animation_tree.set("parameters/Unarmed/transition_request", "locomotion_state")

		
		if rifle_enabled:
			animation_tree.set("parameters/rifle_landed/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		else:
			animation_tree.set("parameters/landed/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		
		was_on_air = false
		last_y_in_floor = transform.origin.y
		is_crouched = false
	
	elif is_crouched:
		
		if rifle_enabled:
			animation_tree.set("parameters/RifleCrouch/blend_position", abs(velocity.x) / max_character_speed_crouched)
			animation_tree.set("parameters/RifleState/transition_request", "crouch_state")
		else:
			animation_tree.set("parameters/Crouch/blend_position", abs(velocity.x) / max_character_speed_crouched)
			animation_tree.set("parameters/Unarmed/transition_request", "crouch_state")
	
	else:

		if rifle_enabled:
			animation_tree.set("parameters/RifleLocomotion/blend_position", abs(velocity.x) / max_character_speed_ground)
			animation_tree.set("parameters/RifleState/transition_request", "locomotion_state")
		else:
			animation_tree.set("parameters/Locomotion/blend_position", abs(velocity.x) / max_character_speed_ground)
			animation_tree.set("parameters/Unarmed/transition_request", "locomotion_state")

	
#-----------------------------------------------------
func animate_on_air():

	animation_tree.set("parameters/OverrideAction/transition_request", "armed_state")

	if rifle_enabled:
		animation_tree.set("parameters/RifleAir/blend_position", abs(velocity.x) / max_character_speed_on_air)
		animation_tree.set("parameters/RifleState/transition_request", "on_air_state")
	else:
		animation_tree.set("parameters/Air/blend_position", abs(velocity.x) / max_character_speed_on_air)
		animation_tree.set("parameters/Unarmed/transition_request", "on_air_state")

	
#-----------------------------------------------------
func animate_climbing():
	
	if climbing_leaving_from_top:

		animation_tree.set("parameters/Crouch/blend_position", 0.0)
		animation_tree.set("parameters/Unarmed/transition_request", "crouch_state")
		animation_tree.set("parameters/OverrideAction/transition_request", "armed_state")

		animation_tree.set("parameters/BraceHangUp/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		
	else:

		var climbingTimeScale = 1.5
		if (velocity.y == 0):
			climbingTimeScale = 0.0
		else:

			animation_tree.set("parameters/Climbing/blend_position", velocity.y / climbing_speed)
			animation_tree.set("parameters/OverrideAction/transition_request", "climbing_state")

		animation_tree.set("parameters/TimeScale Climbing/scale", climbingTimeScale)

	
	
	
#-----------------------------------------------------
#	add here any animation that should be tested to block
#	the cahracter interaction
func is_blocking_animation_running():
	
	if animation_tree.get("parameters/landed/active"):
		return true
	
	if animation_tree.get("parameters/BraceHangUp/active"):
		return true


	return false



#-----------------------------------------------------
#	Setup used inputs
func setup_input():
	
	add_action_key("move_left", KEY_A)
	add_action_key("move_right", KEY_D)
	add_action_key("move_forward", KEY_W)
	add_action_key("move_backward", KEY_S)

	add_action_key("move_jump", KEY_SPACE)

	add_action_key("move_crouch_stand", KEY_C)

	add_action_key("move_run", KEY_SHIFT)

	add_action_key("rifle_enabled", KEY_1)
