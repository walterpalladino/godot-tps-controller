extends Node

@export var door_r : Node3D
@export var door_l : Node3D

@onready var area : Area3D = $Area3D

@export var speed : float = 3.0
@export var time_open : float = 2.0

@export var door_r_closed_angle : float = 0.0
@export var door_r_opened_angle : float = -90.0
@export var door_l_closed_angle : float = 0.0
@export var door_l_opened_angle : float = 90.0

@export var locked : bool = false

@export var activator_group : String = "CHARACTER"

var door_open : bool = false
var animating : bool = false


var door_r_target_y_rotation : float
var door_l_target_y_rotation : float

var count : int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	area.area_entered.connect(_on_area_entered)
	area.area_exited.connect(_on_area_exited)

	# Make sure to not await during _ready.
	door_setup.call_deferred()


func door_setup():

	await get_tree().physics_frame


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:

	if animating:
		update_door()

	if locked:
		return

	if count == 0 and door_open:
		#close_door()
		get_tree().create_timer(time_open).timeout.connect(close_door)



func close_door():

	if count != 0 or !door_open or animating:
		return
		
	door_r_target_y_rotation = deg_to_rad(door_r_closed_angle)
	door_l_target_y_rotation = deg_to_rad(door_l_closed_angle)

	animating = true


func open_door():

	door_r_target_y_rotation = deg_to_rad(door_r_opened_angle)
	door_l_target_y_rotation = deg_to_rad(door_l_opened_angle)				
					
	animating = true

	
func update_door():
	
	var delta : float = get_physics_process_delta_time()
	
	door_r.rotation.y = lerp_angle (door_r.rotation.y, door_r_target_y_rotation, delta * speed)
	door_l.rotation.y = lerp_angle (door_l.rotation.y, door_l_target_y_rotation, delta * speed)

	if abs(angle_difference(door_r.rotation.y, door_r_target_y_rotation)) < 0.01 :
		door_r.rotation.y = door_r_target_y_rotation
		door_l.rotation.y = door_l_target_y_rotation
		animating = false
		door_open = !door_open

#
func _on_body_entered(body: Node3D):
	#print("_on_body_entered")

	if animating:
		return

	if locked:
		return
	
	if !body.is_in_group(activator_group):
		return
		
	if !door_open:
		open_door()
		
	count = count + 1

	
func _on_body_exited(body: Node3D):
	#print("_on_body_exited")
		
	if !body.is_in_group(activator_group):
		return
		
	count = count - 1
	if count < 0:
		count = 0


func _on_area_entered(area: Area3D):
	#print("_on_area_entered")
	pass

func _on_area_exited(area: Area3D):
	#print("_on_area_exited")
	pass
