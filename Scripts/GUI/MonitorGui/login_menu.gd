extends Panel
@export_multiline var password_1:String
@export_multiline var password_2:String
@onready var name_list:ItemList = $ItemList
@onready var password_field:LineEdit = $LineEdit
@onready var welcomeScreen:Panel = $"../WelcomeScreen"
@onready var homeScreen:Panel = $"../Home_Screen"
@onready var bottomBar:Panel = $"../../BottomBar"
@onready var topBar:Panel = $"../../TopBar"
@onready var main_parent = $"../../../../../../.."
@onready var login_list:ItemList = $ItemList

func _ready():
	populate_user_list()


func populate_user_list():
	name_list.clear() 
	for username in main_parent.usernames:
		name_list.add_item(username)

func check_login():
	var selected_index = name_list.get_selected_items()[0] if name_list.get_selected_items().size() > 0 else -1
	if selected_index != -1:  # Make sure a username is selected
		var entered_password = password_field.text
		var correct_password = main_parent.passwords[selected_index]
		if entered_password == correct_password:
			Show_Welcome_screen(name_list.get_item_text(selected_index))
		else:
			print("Incorrect password for " + name_list.get_item_text(selected_index))
	else:
		print("No username selected.")


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
