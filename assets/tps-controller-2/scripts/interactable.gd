extends Node3D

class_name Interactable

enum INTERACTABLE_TYPE { DOOR }

@export_category("Interactable")
@export var interactable_type : INTERACTABLE_TYPE = INTERACTABLE_TYPE.DOOR
@export var interaction_object : Node3D
