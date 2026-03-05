class_name TPSInputController
extends InputController

#@onready var camera_mount : Node3D = get_parent().get_node("CameraMount")
var camera_mount : Node3D 


@export_category("Mouse Settings")
@export var mouse_sensitivity : float = 2


var target_rotation : float = 0.0

func _ready() -> void:
	self.setup_input()
	
	camera_mount = get_parent().get_parent().get_node("CameraMount")


func _process(delta: float) -> void:
	
	super._process(delta)
	
	_interact = Input.is_action_just_pressed("action_interact")

#	_item_selected_0 = Input.is_action_just_pressed("item_selected_0")
#	_item_selected_1 = Input.is_action_just_pressed("item_selected_1")
#	_item_selected_2 = Input.is_action_just_pressed("item_selected_2")
#	_item_selected_3 = Input.is_action_just_pressed("item_selected_3")


func _unhandled_input(event: InputEvent) -> void:
		
	if event is InputEventMouseButton:
		if not Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			capture_mouse()
		
	if event is InputEventKey:
		if event.is_released():
			if event.keycode == KEY_ESCAPE:
			#  if event.is_action_pressed("ui_cancel"):
				release_mouse()

		
	if event is InputEventMouseMotion:
		camera_mount.rotation.x -= event.relative.y * mouse_sensitivity / 1000.0
		camera_mount.rotation_degrees.x = clamp(camera_mount.rotation_degrees.x, -90.0, 30.0)
		camera_mount.rotation.y -= event.relative.x * mouse_sensitivity / 1000.0
		
		target_rotation = fposmod(camera_mount.rotation.y, 2.0 * PI)


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
