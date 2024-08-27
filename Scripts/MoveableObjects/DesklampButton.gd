extends Interactable
@export var light: SpotLight3D = null
@export var lightMesh: MeshInstance3D = null
@export var lampMesh: MeshInstance3D = null
@onready var audio_player = $AudioStreamPlayer3D

func interact():
	audio_player.play()
	if(light != null):
		var tween = get_tree().create_tween()
		if(lightMesh.visible):
			tween.tween_property(lampMesh, "blend_shapes/Key Down", !lightMesh.visible as int, 0.15).set_ease(Tween.EASE_OUT)
		else:
			tween.tween_property(lampMesh, "blend_shapes/Key Down", !lightMesh.visible as int, 0.15).set_ease(Tween.EASE_OUT)
		lightMesh.visible = !lightMesh.visible
		light.visible = !light.visible
