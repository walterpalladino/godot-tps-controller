extends CharacterBody3D


enum CONTROLLER_STATE {LOCOMOTION, ON_AIR}


@onready var _animator_controller : AnimatorController = $AnimatorController
#@onready var collision_shape = get_node("CollisionShape3D")
#@onready var animation_tree : AnimationTree = get_node("AnimationTree")
@onready var model = get_node("Model")


@export_category("Ground Movement")

@export var max_character_speed_ground = 6.0


@export_category("On AIr")
@export var gravity = 9.81
@export var falling_gravity_multiplier = 1.0
@export var jump_height : float = 2.0

## Lapse in mili seconds
@export var max_character_speed_on_air = 4.0
@export var reaction_character_speed_on_air = 1.0

@export var free_air_movement : bool = false

@export var min_time_between_jumps : float = 1.0 # in seconds
var last_jump_time : float = 0.0
var last_y_in_floor : float = 0.0


var was_on_air : bool = false
var last_face_direction : float = 1
var controller_state : CONTROLLER_STATE = CONTROLLER_STATE.ON_AIR

var movement : float = 0.0


#-----------------------------------------------------
func _ready() -> void:
	pass
	

#-----------------------------------------------------
func _physics_process(delta):

	if is_blocking_animation_running():
		return

	update_character(delta)


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


####################################
##	Ground Movement
####################################

func is_grounded():
	#	Check distance to floor
	var distance_to_floor : float  = check_distance_to_floor()
	#print_debug(distance_to_floor)
	return is_on_floor()


func check_distance_to_floor():
	var space_state = get_world_3d().direct_space_state
	
	var origin : Vector3 = global_transform.origin + Vector3.UP * 0.05
	var end = origin + Vector3.DOWN * 100.0
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true

	var result = space_state.intersect_ray(query)
	if !result:
		return 100.0
	else:
		return clamp(transform.origin.y - result.position.y, 0.0, 100.0)


####################################
##	Jump
####################################

func calculate_jump_vertical_speed():
	return sqrt(2.0 * gravity * jump_height)





#-----------------------------------------------------
func update_character(delta):
	
	match controller_state:
		CONTROLLER_STATE.LOCOMOTION:
			update_character_locomotion(delta)
		CONTROLLER_STATE.ON_AIR:
			update_character_on_air(delta)
		



#-----------------------------------------------------
func update_character_on_air(delta):
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

	#	hit ground?
	if is_on_floor():
		was_on_air = true
		controller_state = CONTROLLER_STATE.LOCOMOTION
		return

	var new_velocity = Vector3.ZERO
	
	#	If enabled the Free Air Movement option
	#	the character can change direction on air
	if free_air_movement and input_dir.x != 0.0:
		var direction = Vector3.RIGHT * sign(input_dir.x) 
		new_velocity.x = max_character_speed_on_air * direction.x
	else:
		new_velocity.x = velocity.x
		
		#	If being on air and no horizontal move
		#	the character tries to move, will only be able to do that
		#	on the actual facing direction at a very #	small speed
		#	but enough to climb high steps 
		if new_velocity.x == 0:
			if sign(input_dir.x) == last_face_direction:
				new_velocity.x = sign(input_dir.x) * reaction_character_speed_on_air
		
	
	#	add the gravity.
	var gravity_multiplier : float = 1.0
	if (velocity.y < 0.0):
		gravity_multiplier = falling_gravity_multiplier
	new_velocity.y = velocity.y - gravity_multiplier * gravity * delta
		
	if transform.origin.y > last_y_in_floor:
		last_y_in_floor = transform.origin.y
	
	velocity = new_velocity

	move_and_slide()
	
	update_model_facing()
	update_animations()


	


#-----------------------------------------------------
func update_character_locomotion(delta):
	
	if !is_grounded() :
		controller_state = CONTROLLER_STATE.ON_AIR
		return

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	movement = input_dir.x
	
	# Get the input direction and handle the movement/deceleration.
	var direction : Vector3 = Vector3.RIGHT * sign(input_dir.x) 

	var jump : bool = (input_dir.y < 0.0) #and !is_crouched 


	#	evaluate movement velocity
	var new_velocity = Vector3.ZERO
	var target_speed = 0.0	# depends on if the target is stand or crouched 
	
	if direction.x != 0.0:
		target_speed = max_character_speed_ground
	
	new_velocity.x = target_speed * sign(direction.x) #lerp(abs(velocity.x), target_speed, speed_change * delta) * sign(direction.x)
	new_velocity.z = 0 # No lateral movement - to and from screen
	
		
	# Handle Jump.
	if jump and Time.get_ticks_msec() > last_jump_time + min_time_between_jumps * 1000.0:

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
	move_and_slide()
	
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
			#animate_locomotion()
			_animator_controller.animate_locomotion_ground(false, movement)
		CONTROLLER_STATE.ON_AIR:
			#animate_on_air()
			_animator_controller.animate_on_air()




#-----------------------------------------------------
func animate_locomotion():

	#if was_on_air:
#
		##	Set to be sure the transsition after the one shot is locomotion
		#if rifle_enabled:
			#animation_tree.set("parameters/RifleLocomotion/blend_position", abs(velocity.x) / max_character_speed_ground)
			#animation_tree.set("parameters/RifleState/transition_request", "locomotion_state")
		#else:
			#animation_tree.set("parameters/Locomotion/blend_position", abs(velocity.x) / max_character_speed_ground)
			#animation_tree.set("parameters/Unarmed/transition_request", "locomotion_state")
#
		#
		#if rifle_enabled:
			#animation_tree.set("parameters/rifle_landed/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		#else:
			#animation_tree.set("parameters/landed/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		#
		#was_on_air = false
		#last_y_in_floor = transform.origin.y
		#is_crouched = false
	#
	#elif is_crouched:
		#
		#if rifle_enabled:
			#animation_tree.set("parameters/RifleCrouch/blend_position", abs(velocity.x) / max_character_speed_crouched)
			#animation_tree.set("parameters/RifleState/transition_request", "crouch_state")
		#else:
			#animation_tree.set("parameters/Crouch/blend_position", abs(velocity.x) / max_character_speed_crouched)
			#animation_tree.set("parameters/Unarmed/transition_request", "crouch_state")
	#
	#else:
#
		#if rifle_enabled:
			#animation_tree.set("parameters/RifleLocomotion/blend_position", abs(velocity.x) / max_character_speed_ground)
			#animation_tree.set("parameters/RifleState/transition_request", "locomotion_state")
		#else:
			#animation_tree.set("parameters/Locomotion/blend_position", abs(velocity.x) / max_character_speed_ground)
			#animation_tree.set("parameters/Unarmed/transition_request", "locomotion_state")
	pass
	
#-----------------------------------------------------
func animate_on_air():

	#animation_tree.set("parameters/OverrideAction/transition_request", "armed_state")
#
	#if rifle_enabled:
		#animation_tree.set("parameters/RifleAir/blend_position", abs(velocity.x) / max_character_speed_on_air)
		#animation_tree.set("parameters/RifleState/transition_request", "on_air_state")
	#else:
		#animation_tree.set("parameters/Air/blend_position", abs(velocity.x) / max_character_speed_on_air)
		#animation_tree.set("parameters/Unarmed/transition_request", "on_air_state")
	pass
	
	
#-----------------------------------------------------
func animate_climbing():
	
	#if climbing_leaving_from_top:
#
		#animation_tree.set("parameters/Crouch/blend_position", 0.0)
		#animation_tree.set("parameters/Unarmed/transition_request", "crouch_state")
		#animation_tree.set("parameters/OverrideAction/transition_request", "armed_state")
#
		#animation_tree.set("parameters/BraceHangUp/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		#
	#else:
#
		#var climbingTimeScale = 1.5
		#if (velocity.y == 0):
			#climbingTimeScale = 0.0
		#else:
#
			#animation_tree.set("parameters/Climbing/blend_position", velocity.y / climbing_speed)
			#animation_tree.set("parameters/OverrideAction/transition_request", "climbing_state")
#
		#animation_tree.set("parameters/TimeScale Climbing/scale", climbingTimeScale)
	pass
	
	
	
#-----------------------------------------------------
#	add here any animation that should be tested to block
#	the cahracter interaction
func is_blocking_animation_running():
	
#	if animation_tree.get("parameters/landed/active"):
#		return true
	
#	if animation_tree.get("parameters/BraceHangUp/active"):
#		return true


	return false
