#	File : character_tps2.gd
extends CharacterController3D




#	character_side_action_controller

enum CONTROLLER_STATE {LOCOMOTION, ON_AIR, CLIMBING }


@onready var collision_shape = get_node("CollisionShape3D")
@onready var animation_tree : AnimationTree = get_node("AnimationTree")
@onready var model = get_node("Model")

#@onready var interact_label = get_node("InteractLabel")
@onready var interact_label : Label = get_node("InteractLabel")

@onready var look_at_modifier : LookAtModifier3D = find_child("LookAtModifier3D")

@export_category("Ground Movement")

@export var max_character_speed_walking = 2.0
@export var max_character_speed_running = 6.0
@export var max_character_speed_crouched = 2.0
#@export var speed_change = 50.0
#@export var crouch_speed = 2.0

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


var was_on_air : bool = false


var last_face_direction : Vector3 = Vector3.ZERO


var controller_state : CONTROLLER_STATE = CONTROLLER_STATE.ON_AIR


@export_category("Mouse Settings")
@export var mouse_sensitivity : float = 2

@export_category("Interactions")
@export var interaction_min_distance : float = 0.60
@export var interaction_max_distance : float = 1.20


@export_category("Wall Movement")
@export var climbing_speed : float = 1

var was_climbing : bool = false
var climbing_leaving_from_top : bool = false
var wall_normal_climbing : Vector3 = Vector3.ZERO
#	offset used to adjust end of climbing to top animation
@export var climbing_leaving_from_top_offset : Vector3 = Vector3(-0.50, 1.35, 0.0)




@onready var camera_mount : Node3D = get_parent().get_node("CameraMount")
@onready var camera : Camera3D = camera_mount.get_node("Camera3D")


var movement : Vector2 = Vector2.ZERO
var is_running : bool = false
var is_crouching : bool = false

#var new_velocity : Vector3 = Vector3.ZERO

var turning : float = 0.0

#-----------------------------------------------------
func _ready() -> void:

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	setup_input()
	
	interact_label.visible = false


#-----------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
		
	if event is InputEventMouseButton:
		if not Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
	if event is InputEventKey:
		if event.is_released():
			if event.keycode == KEY_ESCAPE:
			#  if event.is_action_pressed("ui_cancel"):
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseMotion:
		camera_mount.rotation.x -= event.relative.y * mouse_sensitivity / 1000.0
		camera_mount.rotation_degrees.x = clamp(camera_mount.rotation_degrees.x, -90.0, 30.0)
		camera_mount.rotation.y -= event.relative.x * mouse_sensitivity / 1000.0



#-----------------------------------------------------
func _physics_process(delta):

	if is_blocking_animation_running():
		return
		
	check_interactions()
		
	update_character(delta)



func check_interactions():

	var space_state = get_world_3d().direct_space_state

	var mouse_pos = get_viewport().get_mouse_position()

	var origin = camera.project_ray_origin(mouse_pos)
	origin += camera.project_ray_normal(mouse_pos) * interaction_min_distance 
	var end = origin + camera.project_ray_normal(mouse_pos) * interaction_max_distance

	var query : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [self]

	var result = space_state.intersect_ray(query)

	interact_label.visible = false
		
	if result:
		
		if result.collider.has_method("interact"):

			if look_at_modifier:
				if result.collider.interaction_object:
					#print(result.collider.interaction_object.get_path())
					look_at_modifier.active = true
					#look_at_modifier.influence = 1.0
					look_at_modifier.target_node = result.collider.interaction_object.get_path()
					get_tree().create_tween().tween_property(look_at_modifier, "influence", 1, 1)
				else:
					if look_at_modifier.active:
						get_tree().create_tween().tween_property(look_at_modifier, "influence", 0, 1).finished.connect(end_look_at_target)

			if result.collider.is_open():
				interact_label.text = "Close"
			else:
				interact_label.text = "Open"
					
			interact_label.visible = true

			if Input.is_action_just_pressed("action_interact") :
				animate_interactable(result.collider.interactable_type, result.collider.is_open)
				result.collider.interact()
				
		else:
			if look_at_modifier.active:
				get_tree().create_tween().tween_property(look_at_modifier, "influence", 0, 1).finished.connect(end_look_at_target)
	
	else:
		if look_at_modifier.active:
			get_tree().create_tween().tween_property(look_at_modifier, "influence", 0, 1).finished.connect(end_look_at_target)


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
		



	


#-----------------------------------------------------
func update_character_locomotion(delta):
	
	if !is_grounded() :
		controller_state = CONTROLLER_STATE.ON_AIR
		return

	# Get the input direction and handle the movement/deceleration.
	var input_dir : Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	movement = Vector2(input_dir.x, -input_dir.y)
	
	
	if is_on_wall() and input_dir.y < 0.0:
		print("check wall first")
		if check_can_climb_wall(get_facing_direction()):
			print("can climb")
			var inv_normal = Vector2(get_wall_normal().z, get_wall_normal().x).normalized() 
			var inv_normal_wall_angle = rad_to_deg(inv_normal.angle())
			#	Force character face the wall while climbing
			model.rotation.y = deg_to_rad(inv_normal_wall_angle)
			was_climbing = false
			wall_normal_climbing = get_wall_normal()
			controller_state = CONTROLLER_STATE.CLIMBING
			return

	
	
	# Get the input direction and handle the movement/deceleration.
	#var direction : Vector3 = Vector3.RIGHT * sign(input_dir.x) 
	var direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, camera_mount.rotation.y)

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
		turning = sign(model.rotation.y - camera_mount.rotation.y)
		model.rotation.y = lerp_angle(model.rotation.y, camera_mount.rotation.y, rotation_speed * delta)
		
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
		new_velocity = max_character_speed_on_air * direction;
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
	
	#update_model_facing()
	update_animations()



#-----------------------------------------------------
func update_character_on_air(delta):
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir : Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	movement = Vector2(input_dir.x, -input_dir.y)

	#	hit ground?
	if is_grounded():
		was_on_air = true
		controller_state = CONTROLLER_STATE.LOCOMOTION
		return

	if is_on_wall() and input_dir.y < 0.0:
		
		if check_can_climb_wall(get_facing_direction()):
			#print_debug("Now is climbing a wall")
			was_climbing = false
			controller_state = CONTROLLER_STATE.CLIMBING
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
	update_animations()


#-----------------------------------------------------	
func update_character_climbing(delta):
	
	if climbing_leaving_from_top:

		print("climbing_leaving_from_top")
		climbing_leaving_from_top = false
		is_crouched = true
		
		var offset : Vector3 = get_facing_direction() * climbing_leaving_from_top_offset.x #last_face_direction
		offset.y += climbing_leaving_from_top_offset.y
		global_transform.origin += offset
		controller_state = CONTROLLER_STATE.LOCOMOTION
		
		velocity = Vector3.ZERO
		move_and_slide()
		
		return
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	#	leaving from the ground
	if is_on_floor() and input_dir.y > 0.0:
		print_debug("Was climbing")
		was_climbing = true
		controller_state = CONTROLLER_STATE.LOCOMOTION
		return

	#	jumps away the wall
	if input_dir.x != 0:
		print("jumps away the wall")
		velocity = transform.basis.x * 6.0 * sign(input_dir.x)
		velocity.y = 2.0
		move_and_slide()
		was_climbing = true
		controller_state = CONTROLLER_STATE.ON_AIR
		return

	if !check_can_climb_wall(get_facing_direction()):
		
		if wall_collision_result == (WALL_COLLISION_RESULT.COLLISION_MID | WALL_COLLISION_RESULT.COLLISION_BOTTOM):
			#	climbing to the top
			climbing_leaving_from_top = true
			update_animations()
			return
		else:
			# nothing to hold on to...
			print("nothing to hold on to...")
			move_and_slide()
			was_climbing = true
			controller_state = CONTROLLER_STATE.ON_AIR
			return

	var new_velocity : Vector3 = Vector3.ZERO
	new_velocity = get_facing_direction() * 0.1
	new_velocity += Vector3.UP * climbing_speed * -input_dir.y

	velocity = new_velocity
	move_and_slide()

	update_animations()
	

#	Returns character facing direction	
func get_facing_direction() -> Vector3:
	return Vector3.FORWARD.rotated(Vector3.UP, model.rotation.y)


		
#-----------------------------------------------------
func update_model_facing():
	
	if movement.y > 0:
		model.global_rotation.y = lerp_angle( model.global_rotation.y, camera_mount.rotation.y, get_physics_process_delta_time() * rotation_speed )


#-----------------------------------------------------
# Update animations
func update_animations():

	match controller_state:
		CONTROLLER_STATE.LOCOMOTION:
			animate_locomotion()
		CONTROLLER_STATE.ON_AIR:
			animate_on_air()
		CONTROLLER_STATE.CLIMBING:
			animate_climbing()



#-----------------------------------------------------
func animate_locomotion():
	
	if was_on_air:
		animate_locomotion_ground()
		# TODO : Fix not working
		#print(animation_tree.get_property_list())
		#animation_tree.set("parameters/landed/fadeout_time", 0.05)
		var one_shot_node : AnimationNodeOneShot = animation_tree.tree_root.get_node("landed") 
		#one_shot_node.fadeout_time = 0.05
		animation_tree.set("parameters/landed/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		
		was_on_air = false
		last_y_in_floor = transform.origin.y
		is_crouched = false
	
	elif is_crouched:

		animation_tree.set("parameters/State/transition_request", "crouch_state")
		animation_tree.set("parameters/crouch_blend/blend_position", movement)
		
	else:
		animate_locomotion_ground()


func animate_locomotion_ground():
	
	var speed = Vector2(velocity.x, velocity.z).length()
	if speed == 0.0:
		animation_tree.set("parameters/State/transition_request", "idle_state")
		animation_tree.set("parameters/in_place_blend/blend_position", turning)
	elif is_running:
	#	print("running_state")
		animation_tree.set("parameters/State/transition_request", "running_state")
		animation_tree.set("parameters/run_blend/blend_position", movement)
		#print_debug(movement)
	else:
		#print("walking_state")
		#print(movement)
		animation_tree.set("parameters/State/transition_request", "walking_state")
		animation_tree.set("parameters/walk_blend/blend_position", movement)
	

#-----------------------------------------------------
func animate_climbing():
	
	if climbing_leaving_from_top:

		animation_tree.set("parameters/Crouch/blend_position", 0.0)
		animation_tree.set("parameters/State/transition_request", "crouch_state")
		animation_tree.set("parameters/OverrideAction/transition_request", "armed_state")

		animation_tree.set("parameters/BraceHangUp/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		
	else:

		var climbingTimeScale = 1.5
		if (velocity.y == 0):
			climbingTimeScale = 0.0
		else:

			animation_tree.set("parameters/Climbing/blend_position", velocity.y / climbing_speed)
			animation_tree.set("parameters/State/transition_request", "climbing_state")

		animation_tree.set("parameters/TimeScale Climbing/scale", climbingTimeScale)


func animate_interactable(interactable_type : Interactable.INTERACTABLE_TYPE, status):

	if interactable_type == Interactable.INTERACTABLE_TYPE.DOOR:
		animation_tree.set("parameters/OpenDoor/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	
#-----------------------------------------------------
func animate_on_air():

	#animation_tree.set("parameters/OverrideAction/transition_request", "armed_state")

	#animation_tree.set("parameters/Air/blend_position", abs(velocity.x) / max_character_speed_on_air)
	#animation_tree.set("parameters/Unarmed/transition_request", "on_air_state")
	animation_tree.set("parameters/State/transition_request", "on_air_state")

	
	
	
	
#-----------------------------------------------------
#	add here any animation that should be tested to block
#	the cahracter interaction
func is_blocking_animation_running():
	
	if animation_tree.get("parameters/landed/active"):
		return true
	
	if animation_tree.get("parameters/BraceHangUp/active"):
		return true

	if animation_tree.get("parameters/OpenDoor/active"):
		return true

	return false



#-----------------------------------------------------
#	Setup used inputs
func setup_input():
	
	add_action_key("move_left", KEY_A)
	add_action_key("move_right", KEY_D)
	add_action_key("move_forward", KEY_W)
	add_action_key("move_backward", KEY_S)

	add_action_key("move_jump", KEY_SPACE)

	add_action_key("move_crouch_stand", KEY_C)

	add_action_key("move_run", KEY_SHIFT)

	add_action_key("action_interact", KEY_E)
