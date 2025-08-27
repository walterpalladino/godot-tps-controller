extends Area3D

@onready var animation_player : AnimationPlayer = $AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	animation_player.play("coin_floating")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		print_debug("Player entered : " + name)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		print_debug("Player exited : " + name)
