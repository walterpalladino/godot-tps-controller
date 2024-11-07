extends CharacterBody3D

@onready var collision_shape = get_node("CollisionShape3D")
#@onready var animation_player : AnimationPlayer = get_node("Model/AnimationPlayer")
#@export var animation_player : AnimationPlayer
@onready var animation_tree : AnimationTree = get_node("AnimationTree")
@onready var state_machine := animation_tree.get("parameters/side_scroller_sm/playback") as AnimationNodeStateMachinePlayback


@onready var model = get_node("Model")


@export_category("Ground Movement")

@export var walk_speed = 2.0
@export var run_speed = 6.0

@export_category("On AIr")

@export var gravity = 9.81
@export var jump_height : float = 2.0
@export var min_time_between_jumps = 1.0 # in seconds
var last_jump_time : float = 0


# Get the gravity from the project settings to be synced with RigidBody nodes.
#var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


const STEP_RAY_LENGTH = 0.2
#const STEP_OFFSET = Vector3(0.0, 0.1, 0.0)

#var last_direction = Vector2(1.0, 0.0)

#var last_floor_y : float = 0.0
#var last_floor_time : float = 0.0

# steps
#@export_group("Steps", "steps") # All variables with name starting with "prefix" are added to the group.
@export_category("Steps")
@export var max_step_height : float = 0.40

#var on_walkable_step : bool = false

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
	#animation_player.connect("animation_finished", animation_finished)
	pass

func _process(delta: float) -> void:
	#print_debug("_process")
	#print_debug(animation_tree.get_animation_player())
	
	#animation_player = get_node( animation_tree.get_animation_player() )
	#print_debug(animation_player.is_playing())
	#print_debug(animation_player.current_animation)
	#if (is_animation_playing("Idle")):
	#	print_debug("animation playing")
	
	
	# in process or elsewhere:
	var current_node = state_machine.get_current_node()
	print_debug(current_node)
	pass
	

func _physics_process(delta):
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = Vector3.RIGHT * sign(input_dir.x) 

	if is_on_floor():
		is_jumping = false
		is_in_air = false
	else:
		is_in_air = true

	# Test Movement
	#var test_motion_result : PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()
	#var test_motion_parameters : PhysicsTestMotionParameters3D	= PhysicsTestMotionParameters3D.new()
	
	#var test_result : bool = PhysicsServer3D.body_test_motion(get_rid(), test_motion_parameters, test_motion_result)	
	#if test_result:
	#	print("Collided with something trying to move...")


	var new_velocity = Vector3.ZERO
	if direction:
		new_velocity.x = direction.x * walk_speed
		new_velocity.z = 0 # No lateral movement - to and from screen
	else:
		new_velocity.x = move_toward(new_velocity.x, 0, walk_speed)
		new_velocity.z = 0 # No lateral movement - to and from screen
	
	is_step = check_step(delta, new_velocity)

	# Handle Jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
	if is_on_floor():
#		is_step = check_step(delta, new_velocity)

		if input_dir.y < 0.0 and Time.get_ticks_msec() > last_jump_time + min_time_between_jumps * 1000.0:
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
	
	update_model_facing(input_dir)

	update_animations(input_dir)

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
						


func update_model_facing(input_dir):
	
	if input_dir.x != 0.0:
		var face_direction = Vector3( 0.0, sign(input_dir.x) * 90.0, 0.0)
		model.set_rotation_degrees(face_direction)
		last_face_direction = sign(input_dir.x)


# Update animations
func update_animations(input_dir):

	var is_idle : bool = input_dir.x == 0.0 && (is_on_floor() || is_step)
	var is_walking : bool = velocity.x != 0.0 && (is_on_floor() || is_step)
	
	#	Check distance to floor
	var distance_to_floor : float  = check_distance_to_floor()
	if is_on_floor() || is_step:
		distance_to_floor = 0.0
	#print_debug(distance_to_floor)

	var is_grounded : bool = (is_on_floor() || is_step) || (distance_to_floor <= max_step_height)

	animation_tree.set("parameters/side_scroller_sm/conditions/idle", is_idle)
	animation_tree.set("parameters/side_scroller_sm/conditions/idle", is_idle)
	animation_tree.set("parameters/side_scroller_sm/conditions/walking", is_walking)
	animation_tree.set("parameters/side_scroller_sm/conditions/grounded", is_grounded)
	animation_tree.set("parameters/side_scroller_sm/conditions/on_air", !is_grounded)
	#$AnimationTree.set("parameters/conditions/straifLeft", input_dir.x == -1 && is_on_floor())
	#$AnimationTree.set("parameters/conditions/straifRight", input_dir.x == 1 && is_on_floor())
	#$AnimationTree.set("parameters/conditions/falling", !is_on_floor())
	#$AnimationTree.set("parameters/conditions/landed", is_on_floor())


#func animation_finished(anim_name:String):
#	print_debug("animation_finished : " + anim_name)
	
#func add_animation_callback(anim_name:String):
#	animation_tree.connect("animation_finished", animation_finished)
	
#func is_animation_playing(anim_name:String):
#	if (animation_tree .is_playing()):
#		print_debug("something playing...")
#	if (animation_tree.is_playing() && animation_tree.current_animation == anim_name):
#		return true
#	else:
#		return false
		
func calculate_jump_vertical_speed():
	return sqrt(2.0 * gravity * jump_height)
