class_name Doorway
extends Interactable


@export var animation_player : AnimationPlayer


var door_open : bool = false

func is_open():
	return door_open

func interact():

	if animation_player.is_playing():
		return true

	if door_open:
		animation_player.play("close")
		door_open = false
	else:
		animation_player.play("open")
		door_open = true
