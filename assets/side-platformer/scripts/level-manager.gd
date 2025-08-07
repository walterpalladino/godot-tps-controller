extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	setup_input()
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


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
	
	add_action_key("move_left", KEY_A)
	add_action_key("move_right", KEY_D)
	add_action_key("move_forward", KEY_W)
	add_action_key("move_backward", KEY_S)

	add_action_key("move_jump", KEY_SPACE)

	add_action_key("move_crouch_stand", KEY_C)
