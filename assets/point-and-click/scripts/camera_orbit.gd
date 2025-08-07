extends Camera3D

@export var target : Node3D

@export var target_offset : Vector3 = Vector3(0.0, 1.0, 0.0)

# rotation
@export_range (0.0, 100.0, 0.5) var orbit_speed : float = 100.0
@export_range (0.0, 100.0, 0.5) var orbit_radius : float = 10.0
@export_range (0.0, 100.0, 0.5) var orbit_height : float = 10.0


var rotate_direction : int = 0
var orbit_angle : float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_camera(delta)


func _input(event):
	
	rotate_direction = 0
	
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_Q:
			rotate_direction = -1
		elif event.pressed and event.keycode == KEY_E:
			rotate_direction = 1
			
		if event.pressed and event.keycode == KEY_W:
			orbit_radius -= 0.1
		elif event.pressed and event.keycode == KEY_S:
			orbit_radius += 0.1

		if event.pressed and event.keycode == KEY_A:
			orbit_height -= 0.1
		elif event.pressed and event.keycode == KEY_D:
			orbit_height += 0.1



func update_camera(delta):
		
#	if rotate_direction != 0:
		# Update the camera orbit angle
		orbit_angle += delta * orbit_speed * rotate_direction * 10.0 / 1000.0;
		if orbit_angle < 0.0:
			orbit_angle += 360.0
		orbit_angle = fmod(orbit_angle, 360.0)
		
		var orbit_position = Quaternion.from_euler( Vector3(0.0, orbit_angle, 0.0)) * Vector3.RIGHT * orbit_radius

		# Calculate the camera position based on the target position
		var camera_position = target.global_position
		camera_position += orbit_position
		camera_position += Vector3(0.0, orbit_height, 0.0)
		
		global_position = camera_position

		# Update the camera orientation
		look_at(target.global_position + target_offset, Vector3.UP)
