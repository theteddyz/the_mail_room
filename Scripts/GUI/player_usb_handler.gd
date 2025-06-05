extends Node

var usb_list: Dictionary = {
	0: "res://Scenes/Prefabs/gui/usbtest.tscn"
}

@onready var gui_container = $"../GUI/Home_Screen/VBoxContainer"
@onready var parent = $"../../../../.."

func _ready():
	if parent.player_computer:
		check_usb_data()

func check_usb_data():
	var file_name = GameManager.FILE_NAME

	if not FileAccess.file_exists(file_name):
		return

	var save_game = FileAccess.open(file_name, FileAccess.READ)
	if not save_game:
		return

	var save_string = save_game.get_as_text()
	var parsed = JSON.parse_string(save_string)
	save_game.close()

	if typeof(parsed) != TYPE_DICTIONARY:
		return

	var data = parsed

	if not data.has("USB_DATA"):
		return

	for usb in data["USB_DATA"]:
		if typeof(usb) == TYPE_DICTIONARY:
			var id = usb.get("id", -1)
			var added = usb.get("added_to_computer", false)

			if added and usb_list.has(id):
				var scene_path: String = usb_list[id]
				var scene_res: PackedScene = load(scene_path)
				if scene_res:
					var instance = scene_res.instantiate()
					gui_container.add_child(instance)
				else:
					print("Failed to load scene for USB ID %d at path: %s" % [id, scene_path])
