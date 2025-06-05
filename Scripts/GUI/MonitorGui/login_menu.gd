extends Panel
@onready var name_list:Label = $ItemList
@onready var password_field:LineEdit = $LineEdit
@onready var welcomeScreen:Panel = $"../WelcomeScreen"
@onready var homeScreen:Panel =$"../Home_Screen"
@onready var bottomBar:Panel = $"../BottomBar"
@onready var topBar:Panel = $"../TopBar"
@onready var main_parent = $"../../../../../.."

func _ready():
	name_list.text = main_parent.username
func check_login():
	var entered_password = password_field.text
	var correct_password = main_parent.password
	if entered_password == correct_password:
		Show_Welcome_screen(name_list.text)


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
