extends Node3D
@export var username:String
@export var password:String
@export var player_computer:bool = false
@onready var login_menu = $Monitor/ComputerOn/MonitorHandler/SubViewport/GUI/LoginMenu
@onready var bottom_bar = $Monitor/ComputerOn/MonitorHandler/SubViewport/GUI/BottomBar
@onready var top_bar = $Monitor/ComputerOn/MonitorHandler/SubViewport/GUI/TopBar
@onready var home_screen = $Monitor/ComputerOn/MonitorHandler/SubViewport/GUI/Home_Screen
func _ready():
	if player_computer:
		login_menu.visible = false
		top_bar.visible = true
		bottom_bar.visible = true
		home_screen.visible = true
