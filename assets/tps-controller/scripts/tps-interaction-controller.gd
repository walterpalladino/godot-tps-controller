class_name TPSInteractionController
extends InteractionController


var target_marker: Marker3D 


func _ready() -> void:

	super._ready()
	_look_at_modifier.active = false

	target_marker= Marker3D.new()
	add_child(target_marker)



func _process(delta: float) -> void:
	
	super._process(delta)
	
	#track_target()


func track_target():
	
	if !_camera :
		return

	var result = get_cursor_position()

		
	if _look_at_modifier :

		if !result:
			if _look_at_modifier.active && _look_at_modifier.influence == 1.0:
				print("stopped looking")
				get_tree().create_tween().tween_property(_look_at_modifier, "influence", 0, 0.1).finished.connect(end_look_at_target)
			return
				
		#print(result)
		
		#print(result.collider.interaction_object.get_path())
		_look_at_modifier.active = true
		#_look_at_modifier.influence = 1.0
		target_marker.position = result.position
		_look_at_modifier.target_node = target_marker.get_path()

		get_tree().create_tween().tween_property(_look_at_modifier, "influence", 1, 1)
