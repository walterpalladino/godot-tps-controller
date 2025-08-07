extends Camera3D

@export var target : Node3D

@export var camera_offset : Vector3 = Vector3(-20.0, 5.0, 20.0)
@export var camera_rotation : Vector3 = Vector3(-5.4, 0.0, 0.0)


@export var camera_follow_speed : float = 10.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	var camera_position = target.transform.origin + camera_offset
	transform.origin = lerp(transform.origin, camera_position, delta * camera_follow_speed)

	transform.rotated_local(Vector3.UP, camera_rotation.y)	
	transform.rotated_local(Vector3.RIGHT, camera_rotation.x)	
	transform.rotated_local(Vector3.FORWARD, camera_rotation.z)	
