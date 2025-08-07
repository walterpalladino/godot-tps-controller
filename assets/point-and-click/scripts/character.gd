extends CharacterBody3D

const RAY_LENGTH = 1000
const LEFT_MOUSE_BUTTON = 1

#
#const SPEED = 5.0
#const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
#var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


#func _physics_process(delta):
	# Add the gravity.
#	if not is_on_floor():
#		velocity.y -= gravity * delta

	# Handle Jump.
#	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
#		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
#	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
#	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
#	if direction:
#		velocity.x = direction.x * SPEED
#		velocity.z = direction.z * SPEED
#	else:
#		velocity.x = move_toward(velocity.x, 0, SPEED)
#		velocity.z = move_toward(velocity.z, 0, SPEED)

#	move_and_slide()

@onready var navigation_agent : NavigationAgent3D = $NavigationAgent3D
#	Check the character structure: Geometry/model
#	where model represents the 3d model including animationplayer and animationtree
@onready var animation_tree : AnimationTree = get_node("Geometry/model/AnimationTree")
#@export var animation_tree : AnimationTree 
@onready var camera = get_parent_node_3d().get_node("Camera3D")


@export var walking_speed : float = 3.0
@export var running_speed : float = 6.0


# Called when the node enters the scene tree for the first time.
func _ready():
	#motion_mode = MOTION_MODE_GROUNDED

	print_debug("_ready")
	print_debug(get_tree().current_scene.name)
	#print_debug( get_tree().get_root().get_node(get_tree().current_scene.name + "Camera3D") )

	#pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	print_debug("_process")
	if(navigation_agent.is_navigation_finished() || !navigation_agent.is_target_reachable()):
		velocity = Vector3.ZERO
	else:
		move_to_point(delta, walking_speed)

	update_animations()
		

func move_to_point(delta, speed):
	print_debug("move_to_point")
	var target_pos = navigation_agent.get_next_path_position()
	var direction = global_position.direction_to(target_pos)
	
	face_to(target_pos)
	
	var new_velocity = direction * speed
	velocity = velocity.move_toward(new_velocity, delta * 2.5)
	
	move_and_slide()
	

func face_to(target_pos):

	#	Hard Turn
	#look_at(Vector3(target_pos.x, global_position.y, target_pos.z), Vector3.UP)
	#	Soft Turn
	var new_direction: Vector3 = self.global_position.direction_to(Vector3(target_pos.x, global_position.y, target_pos.z))
	var target: Basis = Basis.looking_at(new_direction)
	basis = basis.slerp(target, 0.1)
	
	
	
func _input(event):

	if event is InputEventMouseButton && event.is_pressed() && event.button_index == LEFT_MOUSE_BUTTON: 

		var position = get_world_position()		
		if position:
			navigation_agent.target_position = position
		
		
		
func get_world_position():
	
	var mouse_position = get_viewport().get_mouse_position()
	
	var from = camera.project_ray_origin(mouse_position)
	var to = from + camera.project_ray_normal(mouse_position) * RAY_LENGTH
	var space = get_world_3d().direct_space_state
	
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = from
	ray_query.to = to
	ray_query.collide_with_areas = true
		
	var result = space.intersect_ray(ray_query)
	
	if result:
		return result.position
	else:
		return null


# Update animations
func update_animations():

	var is_idle : bool = velocity.x == 0.0 && velocity.z == 0.0
	var is_walking : bool = velocity.x != 0.0 || velocity.z != 0.0
	
	#print(velocity)
	#print(is_on_floor())
	#print(is_idle)
	#print(is_walking)
	
	animation_tree.set("parameters/conditions/idle", is_idle)
	animation_tree.set("parameters/conditions/walking", is_walking)
	#$AnimationTree.set("parameters/conditions/straifLeft", input_dir.x == -1 && is_on_floor())
	#$AnimationTree.set("parameters/conditions/straifRight", input_dir.x == 1 && is_on_floor())
	#$AnimationTree.set("parameters/conditions/falling", !is_on_floor())
	#$AnimationTree.set("parameters/conditions/landed", is_on_floor())
