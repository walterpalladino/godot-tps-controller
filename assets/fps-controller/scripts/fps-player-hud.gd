extends Control

@onready var health_bar : ProgressBar = $ProgressBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	set_health( 25.0 )

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_health(value : float):
	health_bar.value = value
	
