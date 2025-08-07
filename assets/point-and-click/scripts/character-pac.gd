extends Node3D

const RAY_LENGTH = 1000
const LEFT_MOUSE_BUTTON = 1


@onready var navigation_agent : NavigationAgent3D = $NavigationAgent3D
#	Check the character structure: Geometry/model
#	where model represents the 3d model including animationplayer and animationtree
@onready var animation_tree : AnimationTree = get_node("AnimationTree")
@onready var camera = get_parent_node_3d().get_node("Camera3D")


@export_category("Movement")
@export var walking_speed : float = 4.0

@export var max_distance_to_be_grounded : float = 0.05

#var velocity : Vector3 = Vector3.ZERO
var movement_speed: float = 0.0
var movement_delta : float = 0.0

func _unhandled_input(event: InputEvent) -> void:

	if event is InputEventMouseButton && event.is_pressed() && event.button_index == LEFT_MOUSE_BUTTON: 

		var world_position = get_world_position()		
		if world_position:
			print(world_position)
			navigation_agent.target_position = world_position


func _ready() -> void:
	navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))
	pass

func _physics_process(delta: float) -> void:
	
# Do not query when the map has never synchronized and is empty.
	if NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
		return
				
	if(navigation_agent.is_navigation_finished() || !navigation_agent.is_target_reachable()):
		#velocity = Vector3.ZERO
		movement_speed = 0.0
	else:
		movement_speed = walking_speed
		move_to_point(delta, movement_speed)

	update_animations(movement_speed)

	


#####
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


func move_to_point(delta, movement_speed):
	#print_debug("move_to_point")
	var next_path_position = navigation_agent.get_next_path_position()
	var direction = global_position.direction_to(next_path_position)
	
	face_to(delta, next_path_position)
	
	movement_delta = movement_speed * delta
	var new_velocity : Vector3 = direction * movement_speed
	#velocity = velocity.move_toward(new_velocity, delta * 2.5)
	
	#global_position = global_position.move_toward(global_position + new_velocity, movement_delta)
	#move_and_slide()
	if navigation_agent.avoidance_enabled:
		print("avoidance_enabled")
		navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)
	
	
func _on_velocity_computed(safe_velocity: Vector3) -> void:
	print ("_on_velocity_computed")
	print(safe_velocity)
	global_position = global_position.move_toward(global_position + safe_velocity, movement_delta)
	var distance_to_floor = check_distance_to_floor(global_position)
	#print(distance_to_floor)
	#global_position.y -= distance_to_floor

func face_to(delta, target_pos):

	#	Hard Turn
	#look_at(Vector3(target_pos.x, global_position.y, target_pos.z), Vector3.UP)
	#	Soft Turn
	var new_direction: Vector3 = self.global_position.direction_to(Vector3(target_pos.x, global_position.y, target_pos.z))
	var target: Basis = Basis.looking_at(new_direction)
	basis = basis.slerp(target, delta * 5.0)


####
func update_animations(movement_speed : float):

	var is_idle : bool = movement_speed == 0.0
	var is_walking : bool = movement_speed != 0.0

	if is_idle:
		animation_tree.set("parameters/State/transition_request", "idle_state")
	elif is_walking:	
		animation_tree.set("parameters/State/transition_request", "walking_state")

	
####################################
##	Ground Movement
####################################

func is_grounded():
	#	Check distance to floor
	var distance_to_floor : float  = check_distance_to_floor(global_transform.origin)
	#print_debug(distance_to_floor)
	if distance_to_floor == null:
		return false
	else:
		return abs(distance_to_floor) > max_distance_to_be_grounded


func check_distance_to_floor(check_position : Vector3):
	var space_state = get_world_3d().direct_space_state
	
	var origin : Vector3 = check_position + Vector3.UP * 2.0
	var end = origin + Vector3.DOWN * 10.0
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true

	var result = space_state.intersect_ray(query)
	if !result:
		return null
	else:
		return clamp(transform.origin.y - result.position.y, 0.0, 100.0)
