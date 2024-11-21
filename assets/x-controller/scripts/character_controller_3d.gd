extends CharacterBody3D

class_name CharacterController3D

@export_category("On AIr")

@export var gravity = 9.81
@export var jump_height : float = 2.0



@export_category("Steps")
@export var max_step_height : float = 0.40		# max height for steps
@export var min_step_height : float = 0.001	#	min distance for steps

@export var step_max_slope_degree : float = 15.0

var is_step : bool = false
var is_step_up : bool = false	# true: step up false : step down
var step_diff_position : Vector3 = Vector3.ZERO

var step_margin : float = 0.05



func check_step_move_and_slide():
	var check_velocity : Vector3 = velocity
	check_velocity.y = 0.0
	check_step(check_velocity)
	move_and_slide()
	
	
func check_step(main_velocity:Vector3):
	
	is_step = false
	is_step_up = false
	step_diff_position = Vector3.ZERO
	
	#	if not on floor nothing to check
	if not is_on_floor():
		return false
		
	# do not check if character is idle in case try to jump to avoid detecting collissions with nearby walls
	if main_velocity.length() == 0:
		return false
	
	var test_motion_result: PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()
	var transform3d: Transform3D = global_transform
	var motion: Vector3 = main_velocity * get_physics_process_delta_time()
	
	# ---------------------------------------
	# 1 - test first if can horizontally move
	# ---------------------------------------
	var test_motion_params: PhysicsTestMotionParameters3D = PhysicsTestMotionParameters3D.new()

	test_motion_params.from = transform3d
	test_motion_params.motion = motion
	test_motion_params.recovery_as_collision = true

	var is_character_collided: bool = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
	
	#	the character could move to the end
	if test_motion_result.get_remainder().length() == 0.0:
		
		#	check if there is a step or void bellow
		transform3d.origin += motion
		motion = Vector3.DOWN * max_step_height

		test_motion_params.from = transform3d
		test_motion_params.motion = motion
		test_motion_params.recovery_as_collision = true

		is_character_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)

		if not is_character_collided:
			#	character is in the air
			return false
		
		#	if collided with something check if could be a valid step
		if is_character_collided and -test_motion_result.get_travel().y < max_step_height and -test_motion_result.get_travel().y > min_step_height :
	
			var collision_angle = rad_to_deg(test_motion_result.get_collision_normal().angle_to(Vector3.UP))
			if collision_angle <= step_max_slope_degree:
		
				#print_debug("step down")
				#print_debug(-test_motion_result.get_travel().y )
				is_step = true
				is_step_up = false
				step_diff_position = test_motion_result.get_travel()
				#	adjust the character position
				global_transform.origin += step_diff_position
				
				return true
				
		return false
		
	elif test_motion_result.get_remainder().length() != 0.0:
		#	tried to move but collided with something vertical

		#	now try to move teh controller up to the step height
		#	and check if can move from there
		transform3d.origin += Vector3.UP * (max_step_height + step_margin)

		test_motion_params.from = transform3d
		test_motion_params.motion = motion
		test_motion_params.recovery_as_collision = true

		is_character_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)

		if is_character_collided:
			#print_debug("cant walk there. higher than step")
			return false
		elif not is_character_collided:
			#print_debug("----")
		
			#print_debug(test_motion_result)
			#	check step casting down 
			transform3d.origin += motion 
			motion = Vector3.DOWN * (max_step_height + step_margin)
	
			test_motion_params.from = transform3d
			test_motion_params.motion = motion
			test_motion_params.recovery_as_collision = true
	
			is_character_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
	
			if not is_character_collided:
				return false
	
			var collision_angle = rad_to_deg(test_motion_result.get_collision_normal().angle_to(Vector3.UP))
			#print_debug(collision_angle)
			if collision_angle >= step_max_slope_degree:
				#print_debug("no step, may be a slope")
				return false
				
			if is_character_collided and test_motion_result.get_travel().y < max_step_height + step_margin :#and collision_angle <= step_max_slope_degree:
		
				#print_debug("step up")
				is_step = true
				is_step_up = true
				step_diff_position = -test_motion_result.get_remainder()
				#	adjust the character position
				global_transform.origin += step_diff_position
				
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
			

func calculate_jump_vertical_speed():
	return sqrt(2.0 * gravity * jump_height)


func add_action_key(action, key_code):
	
	if InputMap.has_action(action):
		InputMap.erase_action(action)

	InputMap.add_action(action)
	var event
	event = InputEventKey.new()
	event.keycode = key_code
	InputMap.action_add_event(action, event)
	
	#print_debug(InputMap.get_actions())
	
