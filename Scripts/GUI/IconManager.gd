extends Control

const ICON_TYPE_NAMES = {
	0: "grab",
	1: "light",
	2: "package",
	3: "deliverable",
	4: "key",
	5: "tape"
}

var icons: Dictionary = {}
var object_held = null
var package_held
func _ready():
	EventBus.connect("show_icon", show_icon)
	EventBus.connect("hide_icon", hide_all_icons)
	EventBus.connect("object_looked_at", show_icon)
	EventBus.connect("no_object_found", hide_all_icons)
	EventBus.connect("object_held", held_object)
	EventBus.connect("dropped_object", dropped_object)
	
	for child in get_children():
		if child is TextureRect:
			icons[child.name] = child
			child.hide()

func show_icon(object):
	hide_all_icons(object)

	var icon_name = get_icon_name_for_object(object)

	if icon_name and icons.has(icon_name):
		icons[icon_name].show()

func hide_icon(object):
	var icon_name = get_icon_name_for_object(object)
	if icon_name and icons.has(icon_name):
		icons[icon_name].hide()

func hide_all_icons(object):
	if object is RigidBody3D and object.has_method("hide_label"):
		object.hide_label()

	for name in icons:
		if object_held and name == "grabClosed":
			continue
		icons[name].hide()

func held_object(_unused, held):
	object_held = held
	if object_held is Package:
		package_held = held

func dropped_object(_unused, dropped):
	object_held = null
	if package_held and dropped is Package:
		package_held = null 
	hide_all_icons(null)

# --- Helper Functions ---

func get_icon_name_for_object(object):
	if GrabbingManager.current_grabbed_object == object:
		return "grabClosed"

	if object_held or package_held:
		return get_icon_for_held_object(object)
	else:
		return get_icon_for_free_hand(object)

func get_icon_for_free_hand(object):
	if object is Package:
		object.show_label(object.package_partial_address)

	if "icon_type" in object:
		var type_id = object.icon_type
		if type_id in ICON_TYPE_NAMES:
			return ICON_TYPE_NAMES[type_id]
		return "grab"

	if object.name == "Handlebar":
		return "Drive"

	return null

func get_icon_for_held_object(object):
	#if not (object_held is Package):
		#return "grab"

	match object.name:
		"MailboxStand":
			var deliverable_num = object.get_child(0).accepted_num
			if deliverable_num == package_held.package_num:
				return "deliverable"
		"Basket":
			return "deliverable"
		_:
			return "grab"
