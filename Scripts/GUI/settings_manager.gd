extends Node

const CONFIG_PATH = "user://settings.cfg"

var settings := {
	"video": {
		"resolution": Vector2i(1920, 1080),
		"fullscreen": false,
		"borderless": false,
	},
	"graphics": {
		"vsync": false,
		"ssr": false,
		"shadows": false,
	},
	"gameplay": {
		"disable_shader":false,
		"gi": true,
		"fisheye": 0.0,
		"sharpening": 0.0,
		"mouse_sensitivity":0.25
	}
}

var resolutions := [
	Vector2i(256, 144),
	Vector2i(640, 480),
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]

func _ready():
	load_settings()
	call_deferred("_apply_settings_deferred")

func _apply_settings_deferred():
	await get_tree().process_frame
	apply_settings()

func load_settings():
	var config = ConfigFile.new()
	var err = config.load(CONFIG_PATH)
	if err != OK:
		print("No settings file found. Using defaults.")
		return

	for section in settings:
		for key in settings[section]:
			settings[section][key] = config.get_value(section, key, settings[section][key])

func save_settings():
	var config = ConfigFile.new()
	for section in settings:
		for key in settings[section]:
			config.set_value(section, key, settings[section][key])
	config.save(CONFIG_PATH)

func apply_settings():
	# --- Video Settings ---
	var res = settings["video"]["resolution"]
	var fullscreen = settings["video"]["fullscreen"]
	var borderless = settings["video"]["borderless"]
	var disable_shader = settings["gameplay"]["disable_shader"]
	if !disable_shader:
		for child in get_tree().get_nodes_in_group("Player_shader"):
			child.visible = true
	else :
		for child in get_tree().get_nodes_in_group("Player_shader"):
			child.visible = false
	DisplayServer.window_set_size(res)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, borderless)

	# --- Graphics Settings ---
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if settings["graphics"]["vsync"] else DisplayServer.VSYNC_DISABLED
	)

	EventBus.emit_signal("toggle_shadow_on_dynamic_objects", settings["graphics"]["shadows"])

	var we_list = get_tree().get_nodes_in_group("worldEnvironment")
	if not we_list.is_empty():
		var we: WorldEnvironment = we_list[0]
		if we.environment:
			we.environment.sdfgi_enabled = settings["gameplay"]["gi"]

	# --- Shader Settings (FishEye and Sharpening) ---
	var shader_nodes = get_tree().get_nodes_in_group("Player_shader")
	for shader in shader_nodes:
		shader.material.set_shader_parameter("FISHEYE_AMOUNT", settings["gameplay"]["fisheye"])
		shader.material.set_shader_parameter("SHARPENING", settings["gameplay"]["sharpening"])

func reset_to_defaults():
	settings = {
		"video": {
			"resolution": Vector2i(1920, 1080),
			"fullscreen": false,
			"borderless": false,
		},
		"graphics": {
			"vsync": false,
			"ssr": false,
			"shadows": false,
		},
		"gameplay": {
			"disable_shader":false,
			"gi": true,
			"fisheye": 0.0,
			"sharpening": 0.0
		}
	}
	apply_settings()
	save_settings()

func get_saved_settings() -> Dictionary:
	return settings.duplicate(true)

func get_saved_file_settings() -> Dictionary:
	var fresh_config = ConfigFile.new()
	var err = fresh_config.load(CONFIG_PATH)
	if err != OK:
		print("No saved settings file found, returning current settings.")
		return settings.duplicate(true)

	var loaded_settings := settings.duplicate(true)
	for section in loaded_settings:
		for key in loaded_settings[section]:
			loaded_settings[section][key] = fresh_config.get_value(section, key, loaded_settings[section][key])

	return loaded_settings
