@icon("res://assets/x-controller/CharacterBody3D-X.svg")

extends CharacterBody3D

class_name CharacterController3D

#	Important Notes:
#	1 - Requires the character has a CylinderShape3D as collider shape

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

var step_margin : float = 0.01


@export_category("Walls")
@export var wall_max_cast_dist : float = 0.05 + 0.30
@export var wall_ray_top_offset : float = 1.70
@export var wall_ray_mid_offset : float = 1.00
@export var wall_ray_bottom_offset : float = 0.30

var wall_ray_top_result : Dictionary
var wall_ray_mid_result : Dictionary
var wall_ray_bottom_result : Dictionary


enum WALL_COLLISION_RESULT { COLLISION_NONE = 0, COLLISION_TOP = 1, COLLISION_MID = 2,  COLLISION_BOTTOM = 4 }
var wall_collision_result : WALL_COLLISION_RESULT = WALL_COLLISION_RESULT.COLLISION_NONE



####################################
##	Complex Movement including Steps
####################################
		
func check_step_move_and_slide():
	var check_velocity : Vector3 = velocity
	check_velocity.y = 0.0
	if !check_step(check_velocity):
		move_and_slide()
		apply_floor_snap()
	
	
####################################
##	Steps Movement
####################################

func check_step(check_velocity:Vector3):
	
	is_step = false
	is_step_up = false
	step_diff_position = Vector3.ZERO
	
	#	if not on floor nothing to check
	if not is_on_floor():
		return false
		
	# do not check if character is idle in case try to jump to avoid detecting collissions with nearby walls
	if check_velocity.length() == 0:
		return false
	
	var test_motion_result: PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()
	var transform_test: Transform3D = global_transform
	var motion: Vector3 = check_velocity * get_physics_process_delta_time()
	
	# ---------------------------------------
	# 1 - test first if can horizontally move
	# ---------------------------------------
	var test_motion_params: PhysicsTestMotionParameters3D = PhysicsTestMotionParameters3D.new()

	test_motion_params.from = transform_test
	test_motion_params.motion = motion
	test_motion_params.recovery_as_collision = true

	var is_character_collided: bool = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
	
	#	the character could move to the end
	#	the engine do not include movement on slopes on this category
	#	so will check it later
	#	here will cover straight movement and possible steps down
	if test_motion_result.get_remainder().length() == 0.0:
		
		#	check if there is a step or void bellow
		transform_test.origin += motion
		motion = Vector3.DOWN * (max_step_height + step_margin)

		test_motion_params.from = transform_test
		test_motion_params.motion = motion
		test_motion_params.recovery_as_collision = true

		is_character_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)

		if not is_character_collided:
			#	there is no floor or step below the character
			return false

		#	if collided with something check if could be a valid step
		if -test_motion_result.get_travel().y < max_step_height and -test_motion_result.get_travel().y > min_step_height :

			var collision_angle = rad_to_deg(test_motion_result.get_collision_normal().angle_to(Vector3.UP))
			if collision_angle <= step_max_slope_degree:
		
				#print_debug("step down")

				is_step = true
				is_step_up = false

				step_diff_position = test_motion_result.get_travel()
				
				#	adjust the character position
				global_transform.origin += step_diff_position + min_step_height * Vector3.UP
				
				move_and_slide()
				apply_floor_snap()
				
				return true

		return false
		
	else:
		#	tried to move but collided with something vertical
		#	could be a slope, step up or step higher or wall
		
		var collision_angle = test_motion_result.get_collision_normal().angle_to(Vector3.UP)
		
		#	check if hitted a slope
		if collision_angle <= floor_max_angle:
			#	here is a valid movemnet on a slope
			#	so will leave the engine to handle this
			return false
		
		#	now try to move the controller up to the step height
		#	and check if can move from there
		transform_test.origin += Vector3.UP * (max_step_height + step_margin)

		test_motion_params.from = transform_test
		test_motion_params.motion = motion
		test_motion_params.recovery_as_collision = true

		is_character_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)

		if is_character_collided:
			#	cant walk there. higher than step
			#print_debug("cant walk there. higher than step")
			return false

		#	if we reached here then the movement was blocked as normal
		#	but not at a tep higher so will try to check if movement
		#	is possible

		#print_debug(test_motion_result)
		#	check movement casting down to get the proper step position
		transform_test.origin += motion 
		motion = Vector3.DOWN * (max_step_height + step_margin)
					
		test_motion_params.from = transform_test
		test_motion_params.motion = motion
		test_motion_params.recovery_as_collision = true

		is_character_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)

		if not is_character_collided:
			#	this should never happend
			print("this should never happened")
			return false
		
		if test_motion_result.get_travel().y < (max_step_height + step_margin) :#and collision_angle <= step_max_slope_degree:
	
			#print("step up")
			
			is_step = true
			is_step_up = true
			
			step_diff_position = -test_motion_result.get_remainder()
			
			#	adjust the character position
			global_transform.origin += step_diff_position + min_step_height * Vector3.UP
			
			move_and_slide()
			apply_floor_snap()
			
			return true
		
	return false


func is_on_step() -> bool:
	return is_step


####################################
##	Ground Movement
####################################


func check_collission(origin : Vector3, motion : Vector3):

	var space_state = get_world_3d().direct_space_state
	
	var query = PhysicsRayQueryParameters3D.create(origin, origin + motion + Vector3.DOWN)
	#query.collide_with_areas = true
	query.collide_with_bodies = true

	var result = space_state.intersect_ray(query)
	
	if result:
		print(result.collider.name)

	return result
	

func is_grounded():
	return is_on_floor() || is_on_step()


func check_distance_to_floor():
	var space_state = get_world_3d().direct_space_state
	
	var origin : Vector3 = global_transform.origin + Vector3.UP * 0.05
	var end = origin + Vector3.DOWN * 1000.0
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	query.exclude = [self.get_rid()]

	var result = space_state.intersect_ray(query)
	if !result:
		return 1000.0
	else:
		return clamp(transform.origin.y - result.position.y, 0.0, 100.0)
			

####################################
##	Jump
####################################

func calculate_jump_vertical_speed():
	return sqrt(2.0 * gravity * jump_height)


####################################
##	General Configuration
####################################

func add_action_key(action, key_code):
	
	if InputMap.has_action(action):
		InputMap.erase_action(action)

	InputMap.add_action(action)
	var event
	event = InputEventKey.new()
	event.keycode = key_code
	InputMap.action_add_event(action, event)
	
	#print_debug(InputMap.get_actions())
	


####################################
##	Wall Movement
####################################

#	check ray at head, middle and bottom if they hit a wall
func check_can_climb_wall(direction : Vector3):

	wall_collision_result = WALL_COLLISION_RESULT.COLLISION_NONE
	wall_ray_top_result = {}
	wall_ray_mid_result = {}
	wall_ray_bottom_result = {}

	var space_state = get_world_3d().direct_space_state
	
	#	first ray : top	
	var origin : Vector3 = transform.origin + Vector3.UP * wall_ray_top_offset
	var end = origin + direction.normalized() * wall_max_cast_dist
	var query_params : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()

	query_params.from = origin
	query_params.to = end
	query_params.collide_with_areas = true
	query_params.exclude = [self.get_rid()]

	var result = space_state.intersect_ray(query_params)
	wall_ray_top_result = result
	if result:
		wall_collision_result |= WALL_COLLISION_RESULT.COLLISION_TOP

	#	second ray : middle	
	origin = transform.origin + Vector3.UP * wall_ray_mid_offset
	end = origin + direction.normalized() * wall_max_cast_dist
	
	query_params.from = origin
	query_params.to = end
	query_params.collide_with_areas = true
	query_params.exclude = [self.get_rid()]

	result = space_state.intersect_ray(query_params)
	wall_ray_mid_result = result
	if result:
		wall_collision_result |= WALL_COLLISION_RESULT.COLLISION_MID
		
	#	third ray : bottom	
	origin = transform.origin + Vector3.UP * wall_ray_bottom_offset
	end = origin + direction.normalized() * wall_max_cast_dist
	
	query_params.from = origin
	query_params.to = end
	query_params.collide_with_areas = true
	query_params.exclude = [self.get_rid()]

	result = space_state.intersect_ray(query_params)
	wall_ray_bottom_result = result
	if result:
		wall_collision_result |= WALL_COLLISION_RESULT.COLLISION_BOTTOM
	
	return wall_collision_result == (WALL_COLLISION_RESULT.COLLISION_TOP | WALL_COLLISION_RESULT.COLLISION_MID | WALL_COLLISION_RESULT.COLLISION_BOTTOM)
