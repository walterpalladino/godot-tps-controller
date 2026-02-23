class_name FPSCameraMount
extends Node3D


@export var offset : Vector3 = Vector3(0.0, 1.5, 0.0)

@export var camera : Camera3D 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	camera.current = true
	set_camera_position()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_camera_position() :
	transform.origin = offset

#func set_camera_rotation(rot : float):
#	rotation.x = rot

#func get_camera_rotation() -> float:
#	return rotation.x
