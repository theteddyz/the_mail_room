extends Control
@onready var item_reader:Node = $ItemReader
@onready var icon_manager:Node = $IconManager
@onready var adress_Displayer:Node= $Adress_Displayer
@onready var controls_Displayer:Node = $Controls
func get_item_reader()->Node:
	return item_reader
func get_icon_manager() ->Node:
	return icon_manager

func get_address_displayer() -> Node:
	return adress_Displayer
func get_control_displayer() -> Node:
	return controls_Displayer
