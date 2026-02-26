extends CharacterController3D


#	character_side_action_controller
enum CONTROLLER_STATE {
	LOCOMOTION, 
	ON_AIR, 
	CLIMBING,
	CLIMBING_LEAVING_FROM_TOP 
	}


@onready var _input_controller : InputController = $InputController
#@onready var _movement_controller : MovementController = $MovementController
@onready var _animation_controller : AnimationController = $AnimationController
@onready var _interaction_controller : InteractionController = $InteractionController


@onready var collision_shape = get_node("CollisionShape3D")
@onready var model = get_node("Model")

@onready var look_at_modifier : LookAtModifier3D = find_child("LookAtModifier3D")

@export_category("Ground Movement")

@export var max_character_speed_walking = 2.0
@export var max_character_speed_running = 6.0
@export var max_character_speed_crouched = 2.0

@export var rotation_speed = 12.0

var is_crouched : bool = false


@export_category("On AIr")
## Lapse in mili seconds
@export var gravity_jumping = 9.8
@export var gravity_falling = 16.0
@export var max_character_speed_on_air = 4.0
@export var reaction_character_speed_on_air = 1.0

@export var free_air_movement : bool = false

@export var min_time_between_jumps : float = 1.0 # in seconds
var last_jump_time : float = 0.0
var last_y_in_floor : float = 0.0


var controller_state : CONTROLLER_STATE = CONTROLLER_STATE.ON_AIR


@export_category("Mouse Settings")
@export var mouse_sensitivity : float = 2


@export_category("Wall Movement")
@export var climbing_speed : float = 1.0
@export var climbing_sliding_speed : float = 2.0

#	offset used to adjust end of climbing to top animation
@export var climbing_leaving_from_top_offset : Vector3 = Vector3(-0.50, 1.35, 0.0)

var is_sliding_on_wall : bool = false

@onready var camera_mount : Node3D = get_parent().get_node("CameraMount")
@onready var camera : Camera3D = camera_mount.get_node("Camera3D")


var movement : Vector2 = Vector2.ZERO
var is_running : bool = false


var turning : float = 0.0


#-----------------------------------------------------
func _ready() -> void:

	#_interaction_controller.camera = camera
	pass


#-----------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
		
	if event is InputEventMouseMotion:
		camera_mount.rotation.x -= event.relative.y * mouse_sensitivity / 1000.0
		camera_mount.rotation_degrees.x = clamp(camera_mount.rotation_degrees.x, -90.0, 30.0)
		camera_mount.rotation.y -= event.relative.x * mouse_sensitivity / 1000.0


#-----------------------------------------------------
func _physics_process(delta):

	if _animation_controller.is_blocking_animation_running():
		return
		
	update_character(delta)	
	update_animations()


func end_look_at_target():

	look_at_modifier.target_node = ""
	look_at_modifier.active = false


#-----------------------------------------------------
func update_character(delta):
	
	match controller_state:
		CONTROLLER_STATE.LOCOMOTION:
			update_character_locomotion(delta)
		CONTROLLER_STATE.ON_AIR:
			update_character_on_air(delta)
		CONTROLLER_STATE.CLIMBING:
			update_character_climbing(delta)
		CONTROLLER_STATE.CLIMBING_LEAVING_FROM_TOP:
			update_character_climbing_leaving_from_top(delta)


#-----------------------------------------------------
func update_character_locomotion(delta):
	
	if !is_grounded() :
		controller_state = CONTROLLER_STATE.ON_AIR
		return

	# Get the input direction and handle the movement/deceleration.
	var input_dir : Vector2 = _input_controller.input_dir
	
	movement = Vector2(input_dir.x, -input_dir.y)
	
	if is_on_wall() and input_dir.y < 0.0:

		# check wall first
		if check_can_climb_wall(get_facing_direction()):
			# can climb
			align_model_to_wall()
			controller_state = CONTROLLER_STATE.CLIMBING
			return

	# Get the input direction and handle the movement/deceleration.
	var direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, camera_mount.rotation.y)


	if Vector2(velocity.x, velocity.z).length() <= max_character_speed_crouched :
		if _input_controller.crouch :
			is_crouched = !is_crouched 
			
	var jump : bool = _input_controller.jump
	var running : bool = _input_controller.run

	if !is_crouched && running:
		is_running = true
	else:
		is_running = false

	#	evaluate movement velocity
	var new_velocity = Vector3.ZERO
	var target_speed = 0.0	# depends on if the target is stand or crouched 
	
	if direction.length() > 0:

		update_model_facing()
		
		if is_crouched:
			target_speed = max_character_speed_crouched
		else:
			if is_running:
				target_speed = max_character_speed_running
			else:
				target_speed = max_character_speed_walking
	
	new_velocity = target_speed * direction;
		
	# Handle Jump.
	if jump and Time.get_ticks_msec() > last_jump_time + min_time_between_jumps * 1000.0:

		is_crouched = false
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
	


func align_model_to_wall() :

	var inv_normal = Vector2(get_wall_normal().z, get_wall_normal().x).normalized() 
	var inv_normal_wall_angle = rad_to_deg(inv_normal.angle())
	#	Force character face the wall while climbing
	model.rotation.y = deg_to_rad(inv_normal_wall_angle)
	#wall_normal_climbing = get_wall_normal()


#-----------------------------------------------------
func update_character_on_air(delta):
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir : Vector2 = _input_controller.input_dir
	movement = Vector2(input_dir.x, -input_dir.y)

	#	hit ground?
	if is_grounded():
		#was_on_air = true
		controller_state = CONTROLLER_STATE.LOCOMOTION
		return

	if is_on_wall() and input_dir.y < 0.0:
		
		if check_can_climb_wall(get_facing_direction()):
			controller_state = CONTROLLER_STATE.CLIMBING
			return

	var direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, camera_mount.rotation.y)

	var new_velocity = Vector3.ZERO
	
	#	If enabled the Free Air Movement option
	#	the character can change direction on air
	if free_air_movement and input_dir != Vector2.ZERO:
		new_velocity.x = max_character_speed_on_air * direction.x
		new_velocity.z = max_character_speed_on_air * direction.z
		
		update_model_facing()
	else:
		new_velocity.x = velocity.x
		new_velocity.z = velocity.z
		
		#	If being on air and no horizontal move
		#	the character tries to move, will only be able to do that
		#	on the actual facing direction at a very #	small speed
		#	but enough to climb high steps 
		if new_velocity == Vector3.ZERO:
			#	TODO : Check update
			new_velocity.x = reaction_character_speed_on_air * direction.x
			new_velocity.z = reaction_character_speed_on_air * direction.z
	
	#	add the gravity.
	if velocity.y >= 0.0 :
		new_velocity.y = velocity.y - gravity_jumping * delta
	else:
		new_velocity.y = velocity.y - gravity_falling * delta
		
	if transform.origin.y > last_y_in_floor:
		last_y_in_floor = transform.origin.y
	
	velocity = new_velocity
	
	move_and_slide()
	


#-----------------------------------------------------	
func update_character_climbing(delta):
		
	# Get the input direction and handle the movement/deceleration.
	var input_dir : Vector2 = _input_controller.input_dir
	is_sliding_on_wall = _input_controller.run && input_dir.y > 0
	
	#	leaving from the ground
	if is_on_floor() and input_dir.y > 0.0:
		controller_state = CONTROLLER_STATE.LOCOMOTION
		return

	#	jumps away the wall
	if input_dir.x != 0:
		velocity = transform.basis.x * 6.0 * sign(input_dir.x)
		velocity.y = 2.0
		move_and_slide()
		controller_state = CONTROLLER_STATE.ON_AIR
		return

	if !check_can_climb_wall(get_facing_direction()):
		
		if wall_collision_result == (WALL_COLLISION_RESULT.COLLISION_MID | WALL_COLLISION_RESULT.COLLISION_BOTTOM):
			#	climbing to the top
			controller_state = CONTROLLER_STATE.CLIMBING_LEAVING_FROM_TOP
			return
		else:
			# nothing to hold on to...
			move_and_slide()
			controller_state = CONTROLLER_STATE.ON_AIR
			return

	var new_velocity : Vector3 = Vector3.ZERO
	new_velocity = get_facing_direction() * 0.1
	
	var speed : float = climbing_speed if !is_sliding_on_wall else climbing_sliding_speed
	
	new_velocity += Vector3.UP * speed * -input_dir.y

	velocity = new_velocity
	move_and_slide()
	

func update_character_climbing_leaving_from_top (delta):
	
	is_crouched = true
	
	var offset : Vector3 = get_facing_direction() * climbing_leaving_from_top_offset.x 
	offset.y += climbing_leaving_from_top_offset.y
	global_transform.origin += offset

	controller_state = CONTROLLER_STATE.LOCOMOTION
	
	velocity = Vector3.ZERO

	move_and_slide()


#	Returns character facing direction	
func get_facing_direction() -> Vector3:
	return Vector3.FORWARD.rotated(Vector3.UP, model.rotation.y)
	#return -global_transform.basis.z.normalized()

#-----------------------------------------------------
func update_model_facing():
	
	if movement.length() > 0:
		model.global_rotation.y = lerp_angle( model.global_rotation.y, camera_mount.rotation.y, get_physics_process_delta_time() * rotation_speed )


#-----------------------------------------------------
# Update animations
func update_animations():

	match controller_state:
		CONTROLLER_STATE.LOCOMOTION:
			_animation_controller.animate_locomotion_ground(is_crouched, is_running, movement)
		CONTROLLER_STATE.ON_AIR:
			_animation_controller.animate_on_air()
		CONTROLLER_STATE.CLIMBING:
			_animation_controller.animate_climbing(velocity.y / climbing_speed)
		CONTROLLER_STATE.CLIMBING:
			_animation_controller.animate_climbing_leaving_from_top()
