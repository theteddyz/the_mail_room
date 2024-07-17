extends Control
@onready var item_reader:Node = $ItemReader
@onready var icon_manager:Node = $IconManager
@onready var adress_Displayer:Node= $Adress_Displayer
func get_item_reader()->Node:
	return item_reader
func get_icon_manager() ->Node:
	return icon_manager

func get_address_displayer() -> Node:
	return adress_Displayer
