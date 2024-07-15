extends Control
@onready var item_reader:Node = $ItemReader
@onready var icon_manager:Node = $IconManager

func get_item_reader()->Node:
	return item_reader
func get_icon_manager() ->Node:
	return icon_manager
