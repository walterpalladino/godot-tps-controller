extends Camera3D

@export var target : Node3D
@export var distance : float = 8.0
@export var height : float = 3.0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	var target_position = target.transform.origin
	
	var camera_position = target_position + height * Vector3.UP + distance * Vector3.BACK
	transform.origin = camera_position
	
	look_at_from_position(camera_position, target_position, Vector3.UP)
	
