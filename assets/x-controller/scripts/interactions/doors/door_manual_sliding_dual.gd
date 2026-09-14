extends Interactable

@export var door_r : Node3D
@export var door_l : Node3D

@export var speed : float = 3.0
@export var time_open : float = 2.0

@export var door_r_closed_position_x : float = 0.0
@export var door_r_opened_position_x : float = 0.0
@export var door_l_closed_position_x : float = 0.0
@export var door_l_opened_position_x : float = 0.0

@export var locked : bool = false


var door_open : bool = false
var animating : bool = false


var door_r_target_position_x : float
var door_l_target_position_x : float



func _physics_process(delta: float) -> void:

	if animating:
		update_door()


func close_door():

	if !door_open or animating:
		return
		
	door_r_target_position_x = door_r_closed_position_x
	door_l_target_position_x = door_l_closed_position_x

	animating = true


func open_door():

	door_r_target_position_x = door_r_opened_position_x
	door_l_target_position_x = door_l_opened_position_x
					
	animating = true

	
func update_door():
	
	var delta : float = get_physics_process_delta_time()
	
	door_r.position.x = lerp (door_r.position.x, door_r_target_position_x, delta * speed)
	door_l.position.x = lerp (door_l.position.x, door_l_target_position_x, delta * speed)

	if abs(door_r.global_position.x - door_r_target_position_x) < 0.01 :
		door_r.position.x = door_r_target_position_x
		door_l.position.x = door_l_target_position_x
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
