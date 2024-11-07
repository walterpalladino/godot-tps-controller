extends Node3D

@export var sensitivity := 5
@export var target : Node3D



# Called when the node enters the scene tree for the first time.
func _ready():

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position = target.global_position

	$SpringArm3D/Camera3D.look_at(target.get_node("LookAt").global_position)


func _input(event):
	if event is InputEventMouseMotion:
		#rotation.x -= event.relative.y / 1000 * sensitivity
		#rotation.y -= event.relative.x / 1000 * sensitivity
		var tempRot = rotation.x - event.relative.y / 1000 * sensitivity
		rotation.y -= event.relative.x / 1000 * sensitivity
		tempRot = clamp(tempRot, -1, -.1) # -1, 0.25
		rotation.x = tempRot
		
