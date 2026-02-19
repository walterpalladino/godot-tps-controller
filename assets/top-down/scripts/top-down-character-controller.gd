class_name TopDownCharacterController
extends CharacterBody3D



enum CONTROLLER_STATE {LOCOMOTION, ON_AIR }



@onready var _input_controller : InputController = $"./InputController"
@onready var _animation_controller : AnimationController = $"./AnimationController"
@onready var _interaction_controller : InteractionController = $"./InteractionController"




#@onready var collision_shape = get_node("CollisionShape3D")
#@onready var animation_tree : AnimationTree = get_node("AnimationTree")
@onready var model = get_node("Model")

#@onready var interact_label = get_node("InteractLabel")
#@onready var interact_label : Label = get_node("InteractLabel")


@export_category("Ground Movement")

@export var max_character_speed_walking = 2.0
@export var max_character_speed_running = 6.0
@export var max_character_speed_crouched = 2.0
#@export var speed_change = 50.0
#@export var crouch_speed = 2.0

@export var rotation_speed = 12.0

@export var lock_axis_movement : bool = false

var is_crouched : bool = false


@export_category("On AIr")
## Lapse in mili seconds
@export var gravity_jumping : float = 9.8
@export var gravity_falling : float = 16.0
@export var max_character_speed_on_air : float = 4.0
@export var reaction_character_speed_on_air : float = 1.0

@export var free_air_movement : bool = false

@export var min_time_between_jumps : float = 1.0 # in seconds
var last_jump_time : float = 0.0
var last_y_in_floor : float = 0.0


#var was_on_air : bool = false


var last_face_direction : Vector3 = Vector3.ZERO

@export var gravity = 9.81
@export var jump_height : float = 2.0


var controller_state : CONTROLLER_STATE = CONTROLLER_STATE.ON_AIR



#@export_category("Interactions")
#@export var interaction_min_distance : float = 0.60
#@export var interaction_max_distance : float = 1.20



@onready var camera_mount : Node3D = get_parent().get_node("CameraMount")
@onready var camera : Camera3D = camera_mount.get_node("Camera3D")


var movement : Vector2 = Vector2.ZERO
var is_running : bool = false
var is_crouching : bool = false

#var new_velocity : Vector3 = Vector3.ZERO

#var turning : float = 0.0


var input_dir : Vector2 = Vector2.ZERO


#-----------------------------------------------------
func _ready() -> void:
	
	#GameManaqger.capture_mouse()
	#GameManager.setup_input()
	_input_controller.capture_mouse()
	_input_controller.setup_input()
	
#	interact_label.visible = false


#-----------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
		
	if event is InputEventMouseButton:
		#GameManaqger.capture_mouse()
		_input_controller.capture_mouse()
		
	if event is InputEventKey:
		if event.is_released():
			if event.keycode == KEY_ESCAPE:
				#GameManaqger.release_mouse()
				_input_controller.release_mouse()





#-----------------------------------------------------
func _physics_process(delta):

	if _animation_controller.is_blocking_animation_running():
		return

	# Get the input direction and handle the movement/deceleration.
	set_input_dir()		
#	check_interactions()
	update_character(delta)
	update_animations()



#func check_interactions():
#
	#var space_state = get_world_3d().direct_space_state
#
	#var mouse_pos = get_viewport().get_mouse_position()
#
	#var origin = camera.project_ray_origin(mouse_pos)
	#origin += camera.project_ray_normal(mouse_pos) * interaction_min_distance 
	#var end = origin + camera.project_ray_normal(mouse_pos) * interaction_max_distance
#
	#var query : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, end)
	#query.collide_with_areas = false
	#query.collide_with_bodies = true
	#query.exclude = [self]
#
	#var result = space_state.intersect_ray(query)
#
	#interact_label.visible = false
		#
	#if result:
		#
		#if result.collider.has_method("interact"):
#
			##if look_at_modifier:
				##if result.collider.interaction_object:
					###print(result.collider.interaction_object.get_path())
					##look_at_modifier.active = true
					###look_at_modifier.influence = 1.0
					##look_at_modifier.target_node = result.collider.interaction_object.get_path()
					##get_tree().create_tween().tween_property(look_at_modifier, "influence", 1, 1)
				##else:
					##if look_at_modifier.active:
						##get_tree().create_tween().tween_property(look_at_modifier, "influence", 0, 1).finished.connect(end_look_at_target)
#
			#if result.collider.is_open():
				#interact_label.text = "Close"
			#else:
				#interact_label.text = "Open"
					#
			#interact_label.visible = true
#
			#if Input.is_action_just_pressed("action_interact") :
				#_animation_controller.animate_interactable(result.collider)
				#result.collider.interact()
				#
		#else:
			#pass
			##if look_at_modifier.active:
				##get_tree().create_tween().tween_property(look_at_modifier, "influence", 0, 1).finished.connect(end_look_at_target)
	#
	#else:
		#pass
		##if look_at_modifier.active:
			##get_tree().create_tween().tween_property(look_at_modifier, "influence", 0, 1).finished.connect(end_look_at_target)


func end_look_at_target():
	pass
	#look_at_modifier.target_node = ""
	#look_at_modifier.active = false

		
						
#-----------------------------------------------------
func update_character(delta):
	
	match controller_state:
		CONTROLLER_STATE.LOCOMOTION:
			update_character_locomotion(delta)
		CONTROLLER_STATE.ON_AIR:
			update_character_on_air(delta)
		



func is_grounded():
	return is_on_floor()
	
####################################
##	Jump
####################################

func calculate_jump_vertical_speed():
	return sqrt(2.0 * gravity * jump_height)


func set_input_dir():
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

func get_input_dir():
	return input_dir

#-----------------------------------------------------
func update_character_locomotion(delta : float):
	
	
	if !is_grounded() :
		controller_state = CONTROLLER_STATE.ON_AIR
		return
	
	if lock_axis_movement:
		if input_dir.x != 0.0:
			input_dir.y = 0 
		
		
	movement = Vector2(input_dir.x, -input_dir.y)
	
	
	# Get the input direction and handle the movement/deceleration.
	#var direction : Vector3 = Vector3.RIGHT * sign(input_dir.x) 
	var direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, camera_mount.rotation.y)
#	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()

	last_face_direction = direction

#	if (velocity.x < max_character_speed * 0.5) && (Input.is_action_just_pressed("move_crouch_stand") || Input.is_action_just_pressed("move_backward")):
	if Vector2(velocity.x, velocity.z).length() <= max_character_speed_crouched :
		if Input.is_action_just_pressed("move_crouch_stand") :
			is_crouched = !is_crouched 
			
	var jump : bool = Input.is_action_just_pressed("move_jump")
	var running = Input.is_action_pressed("move_run")

	if !is_crouched && running:
		is_running = true
	else:
		is_running = false

	#	evaluate movement velocity
	var new_velocity = Vector3.ZERO
	var target_speed = 0.0	# depends on if the target is stand or crouched 
	
	if direction.length() > 0:
		
		if is_crouched:
			target_speed = max_character_speed_crouched
		else:
			if is_running:
				target_speed = max_character_speed_running
			else:
				target_speed = max_character_speed_walking
	
	new_velocity = target_speed * direction
		
	# Handle Jump.
	if jump and Time.get_ticks_msec() > last_jump_time + min_time_between_jumps * 1000.0:

		is_crouched = false
		#new_velocity = max_character_speed_on_air * direction;
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
	#update_animations()



#-----------------------------------------------------
func update_character_on_air(delta : float):
	
	# Get the input direction and handle the movement/deceleration.
	movement = Vector2(input_dir.x, -input_dir.y)

	#	hit ground?
	if is_grounded():
		#was_on_air = true
		controller_state = CONTROLLER_STATE.LOCOMOTION		
		
		_animation_controller.animate_locomotion_ground(is_crouched, is_running, movement)
		_animation_controller.animate_land()
		
		last_y_in_floor = transform.origin.y
		is_crouched = false

		return


	var direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, camera_mount.rotation.y)

	var new_velocity = Vector3.ZERO
	
	#	If enabled the Free Air Movement option
	#	the character can change direction on air
	if free_air_movement and input_dir != Vector2.ZERO:
		new_velocity.x = max_character_speed_on_air * direction.x
		new_velocity.z = max_character_speed_on_air * direction.z
	else:
		new_velocity.x = velocity.x
		new_velocity.z = velocity.z
		
		#	If being on air and no horizontal move
		#	the character tries to move, will only be able to do that
		#	on the actual facing direction at a very #	small speed
		#	but enough to climb high steps 
		if new_velocity == Vector3.ZERO:
			
			#print(reaction_character_speed_on_air)
			#	TODO : Check update
			#if sign(input_dir.x) == last_face_direction:
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
	
	update_model_facing()
	#update_animations()


	

#	Returns character facing direction	
func get_facing_direction() -> Vector3:
	return Vector3.FORWARD.rotated(Vector3.UP, model.rotation.y)


		
#-----------------------------------------------------
func update_model_facing():
	
#	if movement != Vector2.ZERO:
#		var facing_angle : float = last_face_direction.signed_angle_to(Vector3.FORWARD, Vector3.DOWN)
#		model.global_rotation.y = lerp_angle( model.global_rotation.y, facing_angle, get_physics_process_delta_time() * 10.0 )
#		#if movement != Vector2.ZERO:
#		#	last_face_direction = sign(velocity.x)

	if last_face_direction.length() > 0:
		model.rotation.y = lerp_angle(model.rotation.y, camera_mount.rotation.y, rotation_speed * get_physics_process_delta_time())


		
#-----------------------------------------------------
# Update animations
func update_animations():

	match controller_state:
		CONTROLLER_STATE.LOCOMOTION:
			_animation_controller.animate_locomotion_ground(is_crouched, is_running, movement)
		CONTROLLER_STATE.ON_AIR:
			_animation_controller.animate_on_air()
