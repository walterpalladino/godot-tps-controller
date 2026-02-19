class_name InputController
extends Node

var _input_dir : Vector2 = Vector2.ZERO
var _jump : bool = false
var _crouch : bool = false
var _run : bool = false
var _interact : bool = false

var _item_selected_0 : bool = false
var _item_selected_1 : bool = false
var _item_selected_2 : bool = false
var _item_selected_3 : bool = false

var input_dir : Vector2 :
	get():
		return _input_dir

var jump : bool :
	get():
		return _jump

var crouch : bool :
	get():
		return _crouch

var run : bool :
	get():
		return _run

var interact : bool :
	get():
		return _interact

var item_selected_0 : bool :
	get():
		return _item_selected_0

var item_selected_1 : bool :
	get():
		return _item_selected_1

var item_selected_2 : bool :
	get():
		return _item_selected_2

var item_selected_3 : bool :
	get():
		return _item_selected_3

var item_selected : int :
	get():
		if _item_selected_0:
			return 0
		if _item_selected_1:
			return 1
		if _item_selected_2:
			return 2
		if _item_selected_3:
			return 3
		return -1


func _process(delta: float) -> void:

	# Get the input direction and handle the movement/deceleration.
	_input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

	_crouch = Input.is_action_just_pressed("move_crouch_stand") 
	_jump = Input.is_action_just_pressed("move_jump")
	_run = Input.is_action_pressed("move_run")




##
func capture_mouse():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func release_mouse():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
