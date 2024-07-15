extends Control

@onready var notes_list = $NotesList
@onready var note_content = $PanelContainer/RichTextLabel
@onready var background_image = $PanelContainer/TextureRect
@onready var panel_container = $PanelContainer
var notes:Dictionary = {}


func _ready():
	hide()

func add_note(title: String, content: String,img:Texture2D):
	if title in notes:
		return
	notes[title] = { "content": content, "image": img }
	update_notes_list()



func update_notes_list():
	for child in notes_list.get_children():
		child.queue_free()
	for title in notes.keys():
		var button = Button.new()
		button.text = title
		button.name = title
		print("NOTE ADDED: " + title)
		var result =  button.pressed.connect(Callable(self, "_on_note_selected"))
		if result != OK:
			print("NOT OKAY FUCK")
		notes_list.add_child(button)
		button.button_pressed = true
		print("Button added for: " + title)

func _on_note_selected():
	print("Button pressed: ")
	#if title in notes:
		#note_content.text = notes[title]["content"]
		#background_image.texture = notes[title]["image"]
		#print(notes[title]["image"])
		#panel_container.show()
	#else:
		#print("Note not found for title: " + title)

func toggle_journal():
	if is_visible_in_tree():
		hide()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().paused = false

















