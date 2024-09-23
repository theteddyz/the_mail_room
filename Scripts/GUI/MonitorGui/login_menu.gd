extends Panel
@export_multiline var password_1:String
@export_multiline var password_2:String
@onready var name_list:ItemList = $ItemList
@onready var password_field:LineEdit = $LineEdit
@onready var welcomeScreen:Panel = $"../WelcomeScreen"
@onready var homeScreen:Panel = $"../Home_Screen"
@onready var bottomBar:Panel = $"../../BottomBar"
@onready var topBar:Panel = $"../../TopBar"



func check_login():
	if password_field.text == password_1 and name_list.is_selected(0):
		Show_Welcome_screen(name_list.get_item_text(0))
	elif password_field.text == password_2 and name_list.is_selected(1):
		Show_Welcome_screen(name_list.get_item_text(1))


func Show_Welcome_screen(n:String):
	hide()
	var text:RichTextLabel = welcomeScreen.get_child(0)
	text.text = "Welcome " + n
	welcomeScreen.show()
	await get_tree().create_timer(1.5).timeout
	welcomeScreen.hide()
	homeScreen.show()
	bottomBar.show()
	topBar.show()
