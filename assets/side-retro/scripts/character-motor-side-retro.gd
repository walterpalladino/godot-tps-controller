class_name CharacterMotorSideRetro

extends Node


@onready var _input_controller : InputControllerSideRetro = $"../InputControllerSideRetro"

@export_category("Ground Movement")

@export var max_character_speed_ground = 5.0
@export var max_character_speed_crouched = 1.0
var is_crouched : bool = false


@export_category("On AIr")

## Lapse in mili seconds
@export var max_character_speed_on_air = 4.0
##	Allows step on platforms when jumping vertically
@export var reaction_speed_on_air = 2.0

@export var free_air_movement : bool = false

##	Manage controlled jumps
@export_category("Jump")
##	Time to reach peak height (in secs)
@export var jump_peak_time : float = .5
##	Time to fall back to starting height (in secs)
@export var jump_fall_time : float = .35
##	Max jump height
@export var jump_height : float = 2.5
##	Jumping distance
@export var jump_distance : float = 6.0
##	Limits the speed when falling
@export var max_falling_speed : float = 8.0
##	Sets min time to keep jump press to get a full jump (in secs)
@export var short_jump_time : float = 0.1

var jump_horizontal_speed : float
var jump_vertical_speed : float
var jump_gravity : float
var fall_gravity : float
##	Min time to allow another jump (in secs)
@export var min_time_between_jumps : float = 1.0
var last_jump_time : float = 0.0
#var last_y_in_floor : float = 0.0



func _ready() -> void:
	
	_calculate_movement_parameters()



#	Initialize some values used on jumps based on parameters
func _calculate_movement_parameters() -> void :

	jump_gravity = (2 * jump_height) / pow( jump_peak_time, 2)
	fall_gravity = (2 * jump_height) / pow( jump_fall_time, 2)
	jump_vertical_speed = jump_gravity * jump_peak_time
	jump_horizontal_speed = jump_distance / (jump_peak_time + jump_fall_time)



func update_character_locomotion(delta, actual_velocity : Vector3) -> Vector3 :
	
	#	Read input
	var input_dir : Vector2 = _input_controller.input_dir
	var crouch_pressed : bool = _input_controller.crouch
	var jump_pressed : bool = _input_controller.jump

	# Get the input direction and handle the movement/deceleration.
	var direction = Vector3.RIGHT * sign(input_dir.x) 

	var jump : bool = jump_pressed and !is_crouched 

	if crouch_pressed:
		is_crouched = !is_crouched 

	#	Evaluate movement velocity
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

		new_velocity.x = jump_horizontal_speed * sign(direction.x)
		new_velocity.y = jump_vertical_speed #calculate_jump_vertical_speed()

		last_jump_time = Time.get_ticks_msec()
		
	elif (new_velocity.y < 0.0):
		#	add a bit to keep the character grounded
		new_velocity.y = -0.1

	return new_velocity
	
	
#-----------------------------------------------------
func update_character_on_air(delta : float, actual_position : Vector3, actual_velocity : Vector3, last_face_direction : float, is_on_wall : bool) -> Vector3 :
	
	#	Read input
	var input_dir : Vector2 = _input_controller.input_dir

	var new_velocity = Vector3.ZERO	
	
	#	If enabled the Free Air Movement option
	#	the character can change direction on air
	if free_air_movement and input_dir.x != 0.0:
		var direction = Vector3.RIGHT * sign(input_dir.x) 
		new_velocity.x = max_character_speed_on_air * direction.x
	else:
		new_velocity.x = actual_velocity.x
		
		#	If being on air and no horizontal move
		#	the character tries to move, will only be able to do that
		#	on the actual facing direction at a very #	small speed
		#	but enough to climb high steps 
		if new_velocity.x == 0 || is_on_wall:
			if sign(input_dir.x) == last_face_direction:
				new_velocity.x = sign(input_dir.x) * reaction_speed_on_air
		
	#	add the effect of gravity
	if (actual_velocity.y > 0.0):
	#	character is jumping
		
		#	Short jump if the stop pressing jump		
		if Time.get_ticks_msec() > last_jump_time + short_jump_time * 1000.0 and (input_dir.y == 0.0):
			actual_velocity.y = actual_velocity.y * 0.5

		new_velocity.y = actual_velocity.y - jump_gravity * delta

	else:
	#	character is falling

		new_velocity.y = actual_velocity.y - fall_gravity * delta
		
		if abs(new_velocity.y) > max_falling_speed :
			new_velocity.y = -max_falling_speed

#	if actual_position.y > last_y_in_floor:
#		last_y_in_floor = actual_position.y
	
	return new_velocity


#-----------------------------------------------------
#

#	var distance_to_floor : float = check_distance_to_floor(transform.origin)
#	print(distance_to_floor)
#	if distance_to_floor > max_step_height:

const F64_MIN: float = -1.7976931348623157e+308
const F64_MAX: float = 1.7976931348623157e+308

func check_distance_to_floor(p_position : Vector3, p_max_distance : float = 100.0) -> float :
	
	var space_state = get_tree().current_scene.get_world_3d().direct_space_state
	
	var origin : Vector3 = p_position + Vector3.UP * 0.05
	var end = origin + Vector3.DOWN * p_max_distance
	
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true

	var result = space_state.intersect_ray(query)
	if !result:
		return F64_MAX
	else:
		return clamp(p_position.y - result.position.y, 0.0, p_max_distance)
