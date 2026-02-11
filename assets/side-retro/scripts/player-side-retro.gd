extends CharacterBody3D


@onready var animation_tree : AnimationTree = get_node("AnimationTree")
@onready var model = get_node("Model")

@onready var _animator_controller : AnimatorControllerSideRetro = $AnimatorControllerSideRetro
@onready var _character_motor : CharacterMotorSideRetro = $CharacterMotorSideRetro


enum CONTROLLER_STATE {LOCOMOTION, ON_AIR}

var controller_state : CONTROLLER_STATE = CONTROLLER_STATE.ON_AIR

var last_face_direction : float = 1



#-----------------------------------------------------
func _ready() -> void:
	pass	


#-----------------------------------------------------
func _physics_process(delta):

	if _animator_controller.is_blocking_animation_running():
		return

	update_character(delta)
	update_model_facing()
	update_animations()


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
func update_character(delta):
		
	#	First check if character is on ground or not
	if is_on_floor() :
		controller_state = CONTROLLER_STATE.LOCOMOTION
	else:		
		controller_state = CONTROLLER_STATE.ON_AIR

	var new_velocity : Vector3 = Vector3.ZERO
	match controller_state:
		CONTROLLER_STATE.LOCOMOTION:
			new_velocity = _character_motor.update_character_locomotion(delta, velocity)
		CONTROLLER_STATE.ON_AIR:
			new_velocity = _character_motor.update_character_on_air(delta, transform.origin, velocity, last_face_direction, is_on_wall())

	velocity = new_velocity
	move_and_slide()	#	Applies delta automatically
	


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
			_animator_controller.animate_locomotion(velocity.x, _character_motor.is_crouched)
		CONTROLLER_STATE.ON_AIR:
			_animator_controller.animate_on_air()
