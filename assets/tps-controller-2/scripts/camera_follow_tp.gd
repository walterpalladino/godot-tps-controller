extends Node3D

@export var target : Node3D

@export var offset : Vector3 = Vector3.ZERO
@export var target_offset : Vector3 = Vector3.ZERO

@export var update_speed : float = 100.0

@export var marker : Node3D

@export var fix_step_jumps = false


			
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	#position = target.position + offset.rotated(Vector3.UP, rotation.y)
	var new_position : Vector3 = position.move_toward(target.position + offset.rotated(Vector3.UP, rotation.y), delta * update_speed)

	var space_state = get_world_3d().direct_space_state

	var ray_origin = target.position + target_offset
	var ray_end = new_position 

	#	To check for oclussion, cast a ray from a target psoition toward the calculated new position
	var query : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [self, target]
	
	query.hit_from_inside = true
	query.hit_back_faces = true

	var result = space_state.intersect_ray(query)
	#	If something was hit, adjust the new position to the collision position
	if result:
		if marker:
			marker.position = result.position
		new_position = position.move_toward(result.position, delta * update_speed)

	position = new_position
	
	#	patch to fix problems with steps jumps
	if fix_step_jumps:
		position.y = target.position.y + offset.rotated(Vector3.UP, rotation.y).y
