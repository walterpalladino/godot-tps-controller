class_name MovementController
extends Node

#	character_side_action_controller

enum CONTROLLER_STATE {LOCOMOTION, ON_AIR, CLIMBING }



@onready var model : Node3D = $"../Model"
#@onready var camera_mount : Node3D = get_parent().get_node("CameraMount")
#@onready var camera : Camera3D = camera_mount.get_node("Camera3D")

@export_group("Rotation")
@export var rotation_speed = 12.0


@export_category("Ground Movement")

@export var max_character_speed_walking = 2.0
@export var max_character_speed_running = 6.0
@export var max_character_speed_crouched = 2.0
#@export var speed_change = 50.0
#@export var crouch_speed = 2.0

#@export var rotation_speed = 12.0

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


var was_on_air : bool = false


@export_category("Wall Movement")
@export var climbing_speed : float = 1

var was_climbing : bool = false
var climbing_leaving_from_top : bool = false
var wall_normal_climbing : Vector3 = Vector3.ZERO
#	offset used to adjust end of climbing to top animation
@export var climbing_leaving_from_top_offset : Vector3 = Vector3(-0.50, 1.35, 0.0)




var last_face_direction : Vector3 = Vector3.ZERO


var controller_state : CONTROLLER_STATE = CONTROLLER_STATE.ON_AIR


var _cc : CharacterController3D
var _input_controller : InputController 
var _movement_controller : MovementController 
var _camera_mount : Node3D
var _model : Node3D


var movement : Vector2 = Vector2.ZERO
var is_running : bool = false
var is_crouching : bool = false

#var new_velocity : Vector3 = Vector3.ZERO

var turning : float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


######
#	Returns character facing direction	
func get_facing_direction() -> Vector3:
	return Vector3.FORWARD.rotated(Vector3.UP, model.rotation.y)


		
#-----------------------------------------------------
func update_model_facing(movement : Vector2):
	
	if movement.y > 0:
		pass
		#model.global_rotation.y = lerp_angle( model.global_rotation.y, camera_mount.rotation.y, get_physics_process_delta_time() * rotation_speed )




#-----------------------------------------------------
func update_character(delta : float):
	
	match controller_state:
		CONTROLLER_STATE.LOCOMOTION:
			update_character_locomotion(delta)
		CONTROLLER_STATE.ON_AIR:
			update_character_on_air(delta)
		CONTROLLER_STATE.CLIMBING:
			update_character_climbing(delta)


#-----------------------------------------------------
func update_character_locomotion(delta):
	
	if !_cc.is_grounded() :
		controller_state = CONTROLLER_STATE.ON_AIR
		return

	# Get the input direction and handle the movement/deceleration.
	var input_dir : Vector2 = _input_controller.input_dir
	movement = Vector2(input_dir.x, -input_dir.y)
	
	
	if _cc.is_on_wall() and input_dir.y < 0.0:
		print("check wall first")
		if _cc.check_can_climb_wall(get_facing_direction()):
			print("can climb")
			var inv_normal = Vector2(_cc.get_wall_normal().z, _cc.get_wall_normal().x).normalized() 
			var inv_normal_wall_angle = rad_to_deg(inv_normal.angle())
			#	Force character face the wall while climbing
			model.rotation.y = deg_to_rad(inv_normal_wall_angle)
			was_climbing = false
			wall_normal_climbing = _cc.get_wall_normal()
			controller_state = CONTROLLER_STATE.CLIMBING
			return

	
	
	# Get the input direction and handle the movement/deceleration.
	var direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, _camera_mount.rotation.y)

	last_face_direction = direction

	if Vector2(_cc.velocity.x, _cc.velocity.z).length() <= max_character_speed_crouched :
#		if Input.is_action_just_pressed("move_crouch_stand") :
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
		turning = sign(model.rotation.y - _camera_mount.rotation.y)
		_model.rotation.y = lerp_angle(model.rotation.y, _camera_mount.rotation.y, rotation_speed * delta)
		
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
		#new_velocity = max_character_speed_on_air * direction;
		new_velocity.y = _cc.calculate_jump_vertical_speed()

		last_jump_time = Time.get_ticks_msec()
		
		_cc.velocity = new_velocity
		_cc.move_and_slide()

		controller_state = CONTROLLER_STATE.ON_AIR
		return

	elif (new_velocity.y < 0.0):
		#	add a bit to keep the character grounded
		new_velocity.y = -0.1

	
	_cc.velocity = new_velocity
	_cc.check_step_move_and_slide()
	
	#update_model_facing()
	#update_animations()



#-----------------------------------------------------
func update_character_on_air(delta):
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir : Vector2 = _input_controller.input_dir
	movement = Vector2(input_dir.x, -input_dir.y)

	#	hit ground?
	if _cc.is_grounded():
		was_on_air = true
		controller_state = CONTROLLER_STATE.LOCOMOTION
		return

	if _cc.is_on_wall() and input_dir.y < 0.0:
		
		if _cc.check_can_climb_wall(get_facing_direction()):
			#print_debug("Now is climbing a wall")
			was_climbing = false
			controller_state = CONTROLLER_STATE.CLIMBING
			return


	var direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, _camera_mount.rotation.y)

	var new_velocity = Vector3.ZERO
	
	#	If enabled the Free Air Movement option
	#	the character can change direction on air
	if free_air_movement and input_dir != Vector2.ZERO:
		new_velocity.x = max_character_speed_on_air * direction.x
		new_velocity.z = max_character_speed_on_air * direction.z
	else:
		new_velocity.x = _cc.velocity.x
		new_velocity.z = _cc.velocity.z
		
		#	If being on air and no horizontal move
		#	the character tries to move, will only be able to do that
		#	on the actual facing direction at a very #	small speed
		#	but enough to climb high steps 
		if new_velocity == Vector3.ZERO:
			#	TODO : Check update
			#if sign(input_dir.x) == last_face_direction:
			new_velocity.x = reaction_character_speed_on_air * direction.x
			new_velocity.z = reaction_character_speed_on_air * direction.z
		
	
	#	add the gravity.
	if _cc.velocity.y >= 0.0 :
		new_velocity.y = _cc.velocity.y - gravity_jumping * delta
	else:
		new_velocity.y = _cc.velocity.y - gravity_falling * delta
		
	if _cc.transform.origin.y > last_y_in_floor:
		last_y_in_floor = _cc.transform.origin.y
	
	_cc.velocity = new_velocity
	
	_cc.move_and_slide()
	
	update_model_facing(movement)
	#update_animations()


#-----------------------------------------------------	
func update_character_climbing(delta):
	
	if climbing_leaving_from_top:

		print("climbing_leaving_from_top")
		climbing_leaving_from_top = false
		is_crouched = true
		
		var offset : Vector3 = get_facing_direction() * climbing_leaving_from_top_offset.x #last_face_direction
		offset.y += climbing_leaving_from_top_offset.y
		_cc.global_transform.origin += offset
		controller_state = CONTROLLER_STATE.LOCOMOTION
		
		_cc.velocity = Vector3.ZERO
		_cc.move_and_slide()
		#camera_mount_update_speed_original = camera_mount.update_speed
		#camera_mount.update_speed = camera_mount_update_speed
		
		return
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir : Vector2 = _input_controller.input_dir
	
	#	leaving from the ground
	if _cc.is_on_floor() and input_dir.y > 0.0:
		print_debug("Was climbing")
		was_climbing = true
		controller_state = CONTROLLER_STATE.LOCOMOTION
		return

	#	jumps away the wall
	if input_dir.x != 0:
		print("jumps away the wall")
		_cc.velocity = _cc.transform.basis.x * 6.0 * sign(input_dir.x)
		_cc.velocity.y = 2.0
		_cc.move_and_slide()
		was_climbing = true
		controller_state = CONTROLLER_STATE.ON_AIR
		return

	if !_cc.check_can_climb_wall(get_facing_direction()):
		
		if _cc.wall_collision_result == (_cc.WALL_COLLISION_RESULT.COLLISION_MID | _cc.WALL_COLLISION_RESULT.COLLISION_BOTTOM):
			#	climbing to the top
			climbing_leaving_from_top = true
			#update_animations()
			return
		else:
			# nothing to hold on to...
			print("nothing to hold on to...")
			_cc.move_and_slide()
			was_climbing = true
			controller_state = CONTROLLER_STATE.ON_AIR
			return

	var new_velocity : Vector3 = Vector3.ZERO
	new_velocity = get_facing_direction() * 0.1
	new_velocity += Vector3.UP * climbing_speed * -input_dir.y

	_cc.velocity = new_velocity
	_cc.move_and_slide()

	#update_animations()
	
	
	
