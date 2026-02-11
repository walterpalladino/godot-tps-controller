class_name InteractionController
extends Node


#@onready var camera : Camera3D
var _camera : Camera3D


@onready var _interact_label : Label = $"../InteractLabel"
@onready var _input_controller : InputController = $"../InputControlller"
@onready var _look_at_modifier : LookAtModifier3D = find_child("LookAtModifier3D")
@onready var _animation_controller : AnimationtController = $"../AnimationController"


@export_category("Interactions")
@export var interaction_min_distance : float = 0.60
@export var interaction_max_distance : float = 1.20


var camera : Camera3D :
	set(new_value):
		_camera = new_value


func _ready() -> void:

	_interact_label.visible = false
	_camera = get_viewport().get_camera_3d()


func _process(delta: float) -> void:
	
	if _animation_controller.is_blocking_animation_running():
		return		
	check_interactions()



func check_interactions():
	
	if !_camera :
		return

	#	Because Node is not spatial we need to get the world3d from the viewport
	var world = get_viewport().world_3d
	var space_state = world.direct_space_state

	var mouse_pos = get_viewport().get_mouse_position()

	var origin = _camera.project_ray_origin(mouse_pos)
	origin += _camera.project_ray_normal(mouse_pos) * interaction_min_distance 
	var end = origin + _camera.project_ray_normal(mouse_pos) * interaction_max_distance

	var query : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [self.get_parent()]

	var result = space_state.intersect_ray(query)

	_interact_label.visible = false
		
	if result:
		
		if result.collider.has_method("interact"):

			if _look_at_modifier :

				if result.collider.interaction_object :
					#print(result.collider.interaction_object.get_path())
					_look_at_modifier.active = true
					#look_at_modifier.influence = 1.0
					_look_at_modifier.target_node = result.collider.interaction_object.get_path()
					get_tree().create_tween().tween_property(_look_at_modifier, "influence", 1, 1)
				else:
					if _look_at_modifier.active:
						get_tree().create_tween().tween_property(_look_at_modifier, "influence", 0, 1).finished.connect(end_look_at_target)

			if result.collider.is_open():
				_interact_label.text = "Close"
			else:
				_interact_label.text = "Open"
					
			_interact_label.visible = true

			if _input_controller.interact :
				_animation_controller.animate_interactable(result.collider.is_open)
				result.collider.interact()
				
		else:
			if _look_at_modifier && _look_at_modifier.active:
				get_tree().create_tween().tween_property(_look_at_modifier, "influence", 0, 1).finished.connect(end_look_at_target)
	
	else:
		if _look_at_modifier && _look_at_modifier.active:
			get_tree().create_tween().tween_property(_look_at_modifier, "influence", 0, 1).finished.connect(end_look_at_target)


func end_look_at_target():

	if _look_at_modifier :
		_look_at_modifier.target_node = ""
		_look_at_modifier.active = false
