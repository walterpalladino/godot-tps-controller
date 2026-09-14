extends Interactable

@export var door : Node3D

@export var speed : float = 3.0

@export var door_closed_angle : float = 0.0
@export var door_opened_angle : float = -90.0

@export var locked : bool = false

var door_target_y_rotation : float

@export var door_open : bool = false
var animating : bool = false




func _physics_process(delta: float) -> void:

	if animating:
		update_door()


func close_door():

	if !door_open or animating:
		return
		
	door_target_y_rotation = deg_to_rad(door_closed_angle)

	animating = true


func open_door():

	door_target_y_rotation = deg_to_rad(door_opened_angle)
					
	animating = true


func update_door():
	
	var delta : float = get_physics_process_delta_time()

	door.rotation.y = lerp_angle(door.rotation.y, door_target_y_rotation, delta * speed)
	
	if abs(angle_difference(door.rotation.y, door_target_y_rotation)) < 0.01 :
		door.rotation.y = door_target_y_rotation
		animating = false
		door_open = !door_open


func interact():
	
	if animating:
		return
		
	if locked:
		return

	if door_open:
		close_door()
	else:
		open_door()


func get_status() -> String:
	var status = ""
	
	if locked:
		status = "LOCKED_"
		
	if door_open:
		status = status + "OPEN"
	else:
		status = status + "CLOSED"
		
	return status


func get_interaction_description() -> String:
	if locked:
		return "Door Locked"
	elif door_open:
		return "Close Door"
	else:
		return "Ope Door"
