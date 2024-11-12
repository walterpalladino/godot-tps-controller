extends CharacterBody3D
class_name CharacterController3D

@export_category("Steps")
@export var max_step_height : float = 0.40

@export var step_max_slope_degree : float = 40.0

var is_step : bool = false
var is_step_up : bool = false	# true: step up false : step down
var step_diff_position : Vector3 = Vector3.ZERO


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
			


func add_action_key(action, key_code):
	
	if InputMap.has_action(action):
		InputMap.erase_action(action)

	InputMap.add_action(action)
	var event
	event = InputEventKey.new()
	event.keycode = key_code
	InputMap.action_add_event(action, event)
	
	#print_debug(InputMap.get_actions())
	
