extends Interactable
@export var light: SpotLight3D = null

func interact():
	print("INTERACTED WITH LAMP")
	if(light != null):
		print("LAMP WAS NOT NULL")
		light.visible = !light.visible
