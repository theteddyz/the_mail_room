extends Interactable
@export var light: SpotLight3D = null

func interact():
	if(light != null):
		light.visible = !light.visible
