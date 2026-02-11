extends Node3D

@export var target : Node3D

@export var offset : Vector3 = Vector3.ZERO

@export var update_speed : float = 100.0

@onready var camera : Camera3D = $Camera3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	position = lerp(position, target.position + offset, delta * update_speed)
	camera.look_at(target.position)
