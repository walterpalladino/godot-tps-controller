extends Camera3D

@export var target : Node3D

@export var camera_offset : Vector3 = Vector3(0.0, 1.5, 3.0)
@export var look_at_offset : Vector3 = Vector3(0.0, 1.5, 0.0)

@export var camera_follow_speed : float = 10.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	var target_position = target.transform.origin + look_at_offset
	var camera_position = target.transform.origin + camera_offset
	
	transform.origin = camera_position
	
	look_at_from_position(camera_position, target_position, Vector3.UP)
	
