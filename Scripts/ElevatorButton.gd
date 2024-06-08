extends Interactable

@export var target_scene_path := ""

func interact():
	GameManager.goto_scene(target_scene_path)
