class_name SidePlatformerAnimatorController
extends AnimationController


@onready var _animation_tree : AnimationTree = $"../AnimationTree"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func animate_locomotion_ground(is_crouched : bool, speed : float):
	
	if !is_crouched:

		if abs(speed) > 0.0 :
			_animation_tree.set("parameters/Transition/transition_request", "state_walk")
		else:
			_animation_tree.set("parameters/Transition/transition_request", "state_idle")

	else:		

		if abs(speed) > 0.0 :
			_animation_tree.set("parameters/Transition/transition_request", "state_crouch_walk")
		else:
			_animation_tree.set("parameters/Transition/transition_request", "state_crouch_idle")



#-----------------------------------------------------
func animate_on_air():

	#_animation_tree.set("parameters/State/transition_request", "on_air_state")
	_animation_tree.set("parameters/Transition/transition_request", "state_on_air")
