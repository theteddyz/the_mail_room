extends Control
@onready var stamina_bar = $ProgressBar



func _ready():
	stamina_bar.value = 200.0

func update_stamina_bar(value:float):
	stamina_bar.value = value
