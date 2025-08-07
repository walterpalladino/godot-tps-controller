extends Camera3D

const MID_MOUSE_BUTTON = 3


# rotation
@export_range (0, 90) var min_elevation_angle : int = 10 
@export_range (0, 90) var max_elevation_angle : int = 80
@export_range (0.0, 100.0, 0.5) var rotation_speed : float = 20.0

@export var inverted_y: bool = false

var is_rotating = false
var last_mouse_position = Vector2()


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_rotating:
		var mouse_speed = get_mouse_speed()
		rotate_camera(mouse_speed.x, delta)
		elevate_camera(mouse_speed.y, delta)



func _input(event):
	
	if event is InputEventMouseButton && event.button_index == MID_MOUSE_BUTTON:
		if event.is_pressed(): 
			is_rotating = true	
		elif event.is_released():
			is_rotating = false
			
			
func rotate_camera(amount: float, delta: float) -> void:
	rotation_degrees.y += rotation_speed * amount * delta


func elevate_camera(amount: float, delta: float) -> void:
	var new_elevation = rotation_degrees.x
	if inverted_y:
		new_elevation += rotation_speed * amount * delta
	else:
		new_elevation -= rotation_speed * amount * delta
	rotation_degrees.x = clamp(
		new_elevation, -max_elevation_angle, -min_elevation_angle
		)
		

func get_mouse_speed() -> Vector2:
	# calculate speed
	var current_mouse_pos = get_viewport().get_mouse_position()
	var mouse_speed = current_mouse_pos - last_mouse_position
	# update last click position
	last_mouse_position = current_mouse_pos
	# return speed
	return mouse_speed
