class_name AnimationtController
extends Node


@onready var _animation_tree : AnimationTree = $"../AnimationTree"




#-----------------------------------------------------
func animate_land() :
	
	_animation_tree.set("parameters/landed/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		

func animate_crouch(movement : Vector2) :

	_animation_tree.set("parameters/State/transition_request", "crouch_state")
	_animation_tree.set("parameters/crouch_blend/blend_position", movement)
		


func animate_locomotion_ground(is_crouched : bool, is_running : bool, movement : Vector2):
	
	if is_crouched:

#		_animation_tree.set("parameters/crouch_blend/blend_position", movement.length())
		_animation_tree.set("parameters/crouch_blend/blend_position", movement.normalized())
		_animation_tree.set("parameters/State/transition_request", "crouch_state")

	else:

		if movement.length() == 0.0:
			_animation_tree.set("parameters/in_place_blend/blend_position", 0.0)
			_animation_tree.set("parameters/State/transition_request", "idle_state")
		elif is_running:
			_animation_tree.set("parameters/run_blend/blend_position", movement.normalized())
			_animation_tree.set("parameters/State/transition_request", "running_state")
		else:
			_animation_tree.set("parameters/walk_blend/blend_position", movement.normalized())
			_animation_tree.set("parameters/State/transition_request", "walking_state")



#	TODO : Review logic to identify action
func animate_interactable(interactable) :

	if interactable is Doorway:
		_animation_tree.set("parameters/OpenDoor/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	
#-----------------------------------------------------
func animate_on_air():

	_animation_tree.set("parameters/State/transition_request", "on_air_state")

	
	
#-----------------------------------------------------
func animate_climbing(speed : float):
	
	var climbingTimeScale = 1.5
	if speed == 0 :
		
		climbingTimeScale = 0.0
		
	else:

		_animation_tree.set("parameters/Climbing/blend_position", speed)
		_animation_tree.set("parameters/State/transition_request", "climbing_state")

	_animation_tree.set("parameters/TimeScale Climbing/scale", climbingTimeScale)
	

func animate_climbing_leaving_from_top():
	
#
	_animation_tree.set("parameters/Crouch/blend_position", 0.0)
	_animation_tree.set("parameters/State/transition_request", "crouch_state")
	_animation_tree.set("parameters/OverrideAction/transition_request", "armed_state")

	_animation_tree.set("parameters/rise_on_top/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	
#-----------------------------------------------------
#	add here any animation that should be tested to block
#	the cahracter interaction
func is_blocking_animation_running():
	
	if _animation_tree.get("parameters/landed/active"):
		return true
	
	if _animation_tree.get("parameters/rise_on_top/active"):
		return true

	if _animation_tree.get("parameters/OpenDoor/active"):
		return true

	return false
