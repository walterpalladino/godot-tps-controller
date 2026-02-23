extends CharacterBody3D

@onready var model : Node3D = get_node("Model")
#@onready var camera_mount : Node3D = get_node("CameraMount")


@export_category("Mouse Settings")
@export var mouse_sensitivity : float = 2



@onready var camera_mount : Node3D = get_node("CameraMount")

@export var camera_offset : Vector3 = Vector3(0.0, 1.5, 0.0)



@export var hud_scene : PackedScene
var hud : Control

@export var character_motor_scene : PackedScene
#var character_motor : FPSCharacterMotor



var last_turning_value : float = 0




func _ready() -> void:

	#GameManager.capture_mouse()
	
	set_camera_position()
		
	if hud_scene:
		hud = hud_scene.instantiate()
		add_child(hud)
		
	#if character_motor_scene:
	#	character_motor = character_motor_scene.instantiate()
	#	add_child(character_motor)
		
		
	#GameManager.setup_input()

	hide_model_geometry()

		

func _unhandled_input(event: InputEvent) -> void:

	if !camera_mount:
		return
			
	if event is InputEventMouseMotion:
		#	rotate the player
		rotate_y( -event.relative.x / 1000 * mouse_sensitivity )

		#	rotate the camera around its pivot
		#	clamp the value
		var temp_rot = camera_mount.rotation.x - event.relative.y / 1000 * mouse_sensitivity
		temp_rot = clamp(temp_rot, -0.8, 1.0) # -1, 0.25
		camera_mount.rotation.x = temp_rot
		
		#print_debug(camera_mount.rotation.x)
		
	if event is InputEventMouseButton:
#		if not Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
#			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		#GameManager.capture_mouse()	
		pass	
		
	if event is InputEventKey:
		if event.is_released():
			if event.keycode == KEY_ESCAPE:
			#  if event.is_action_pressed("ui_cancel"):
				#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				#GameManager.release_mouse()
				pass
		
		
func _physics_process(delta: float) -> void:

	if !camera_mount:
		return
	
	#character_motor.update(self, delta)



#
func hide_model_geometry() -> void:
	for child in model.find_children("*", "VisualInstance3D"):
		child.set_layer_mask_value(1, false)
		child.set_layer_mask_value(2, true)
		

func set_camera_position() :
	camera_mount.transform.origin = camera_offset
