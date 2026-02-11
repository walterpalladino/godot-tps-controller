class_name InputControllerSideRetro

extends Node

var _input_dir : Vector2 = Vector2.ZERO
var _jump : bool = false
var _crouch : bool = false
var _run : bool = false
var _interact : bool = false


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
		
		
func _ready() -> void:
	setup_input()


func _process(delta: float) -> void:

	# Get the input direction and handle the movement/deceleration.
	_input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

	#_crouch = Input.is_action_just_pressed("move_crouch_stand") 
	_crouch = Input.is_action_just_pressed("move_crouch_stand") || Input.is_action_just_pressed("move_backward")

	#_jump = Input.is_action_just_pressed("move_jump")
	_jump = (input_dir.y < 0.0)
	
	_run = Input.is_action_pressed("move_run")

	_interact = Input.is_action_just_pressed("action_interact")



func _unhandled_input(event: InputEvent) -> void:
		
	if event is InputEventMouseButton:
		if not Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			capture_mouse()
		
	if event is InputEventKey:
		if event.is_released():
			if event.keycode == KEY_ESCAPE:
			#  if event.is_action_pressed("ui_cancel"):
				release_mouse()


####################################
##	General Configuration
####################################

func add_action_key(action, key_code):
	
	if InputMap.has_action(action):
		InputMap.erase_action(action)

	InputMap.add_action(action)
	var event
	event = InputEventKey.new()
	event.keycode = key_code
	InputMap.action_add_event(action, event)
	
	#print_debug(InputMap.get_actions())


#-----------------------------------------------------
#	Setup used inputs
func setup_input():
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	add_action_key("move_left", KEY_A)
	add_action_key("move_right", KEY_D)
	add_action_key("move_forward", KEY_W)
	add_action_key("move_backward", KEY_S)

	add_action_key("move_jump", KEY_SPACE)

	add_action_key("move_crouch_stand", KEY_C)

	add_action_key("move_run", KEY_SHIFT)

	add_action_key("action_interact", KEY_E)

##
func capture_mouse():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func release_mouse():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
##
