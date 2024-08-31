extends Control
@onready var item_reader:Node = $ItemReader
@onready var icon_manager:Node = $IconManager
@onready var adress_Displayer:Node= $Adress_Displayer
@onready var controls_Displayer:Node = $Controls
@onready var stamina_bar:Node = $Stamina
@onready var item_icon:Node = $ItemIcon
@onready var cross_hair:Node = $look_icon 
@onready var loading_screen:Node = $loading_screen
func get_item_reader()->Node:
	return item_reader
func get_icon_manager() ->Node:
	return icon_manager
func get_item_icon_displayer()-> Node:
	return item_icon
func get_address_displayer() -> Node:
	return adress_Displayer
func get_control_displayer() -> Node:
	return controls_Displayer
func get_stamina_bar() -> Node:
	return stamina_bar
func get_loading_screen()->Node:
	return loading_screen
func get_crosshair() -> Node:
	return cross_hair
