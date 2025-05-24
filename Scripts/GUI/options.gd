extends Control

@onready var pause_menu = $"../pauseMenu"

# VIDEO TAB
@onready var resolution_option = $Panel/TabContainer/Video/Resolutions/Resolutions
@onready var fullscreen_checkbox = $Panel/TabContainer/Video/Fullscreen_toggle/Fullscreen_Toggle
@onready var borderless_toggle = $Panel/TabContainer/Video/Borderless_Toggle/Borderless_Toggle

# GRAPHICS TAB
@onready var vsync_toggle = $Panel/TabContainer/Graphics/Vsync/Vsync
@onready var ssr_toggle = $Panel/TabContainer/Graphics/SSR/SSR
@onready var shadow_toggle = $Panel/TabContainer/Graphics/Shadows/Shadows
@onready var graphics_fisheye_label = $Panel/TabContainer/GamePlay/FishEye/Label
@onready var graphics_fisheye_slider = $Panel/TabContainer/GamePlay/FishEye/Fish_Eye
@onready var graphics_sharpening_label = $Panel/TabContainer/GamePlay/Sharpening/Label
@onready var graphics_sharpening_slider = $Panel/TabContainer/GamePlay/Sharpening/Sharpening2
@onready var graphics_gi_toggle = $Panel/TabContainer/GamePlay/Global_Illumination/Global_Illumination

# GAMEPLAY TAB
@onready var gameplay_fisheye_label = $Panel/TabContainer/GamePlay/FishEye/Label
@onready var gameplay_fisheye_slider = $Panel/TabContainer/GamePlay/FishEye/Fish_Eye
@onready var gameplay_sharpening_label = $Panel/TabContainer/GamePlay/Sharpening/Label
@onready var gameplay_sharpening_slider = $Panel/TabContainer/GamePlay/Sharpening/Sharpening2
@onready var gameplay_gi_toggle = $Panel/TabContainer/GamePlay/Global_Illumination/Global_Illumination
@onready var gameplay_disable_shader = $Panel/TabContainer/GamePlay/Disable_Shader_Effect/Disable_Shader_Effect
@onready var gameplay_mouse_sensitivity_slider = $Panel/TabContainer/GamePlay/Mouse_sensativtiy/Mouse_sensativity
@onready var gameplay_mouse_sensitivity_label = $Panel/TabContainer/GamePlay/Mouse_sensativtiy/Label


# BOTTOM BUTTONS
@onready var apply_button = $Panel/VBoxContainer/Apply
@onready var exit_button = $Panel/VBoxContainer/Exit

@onready var preview_viewport = $Options_Preview/SubViewport
@onready var preview_scene = $Options_Preview
var shader
var working_settings := {}

@onready var toggles := {
	"graphics/vsync": vsync_toggle,
	"graphics/ssr": ssr_toggle,
	"graphics/shadows": shadow_toggle,
	"gameplay/gi": graphics_gi_toggle,
	"video/borderless": borderless_toggle
}


func _ready():
	for child in get_tree().get_nodes_in_group("Player_shader"):
		if child.name == "everything":
			shader = child.material
	
	graphics_fisheye_label.text = str(shader.get_shader_parameter("FISHEYE_AMOUNT"))
	graphics_sharpening_label.text = str(shader.get_shader_parameter("SHARPENING"))
	hide()
	working_settings = SettingsManager.settings.duplicate(true)
	_init_resolution_ui()
	apply_working_settings_to_ui()
	connect_signals()
	_update_borderless_visibility()
	hide_preview_scene()

func _init_resolution_ui():
	for res in SettingsManager.resolutions:
		resolution_option.add_item("%d x %d" % [res.x, res.y])

	var current_res = working_settings["video"]["resolution"]
	for i in SettingsManager.resolutions.size():
		if SettingsManager.resolutions[i] == current_res:
			resolution_option.select(i)
			break

func apply_working_settings_to_ui():
	fullscreen_checkbox.button_pressed = working_settings["video"]["fullscreen"]
	borderless_toggle.button_pressed = working_settings["video"]["borderless"]
	
	for key in toggles.keys():
		var section = key.get_slice("/", 0)
		var name = key.get_slice("/", 1)
		var value

		# Safely check if section and name exist
		if working_settings.has(section) and working_settings[section].has(name):
			value = working_settings[section][name]
		else:
			# If missing, fallback to current SettingsManager.settings
			value = SettingsManager.settings.get(section, {}).get(name)
		toggles[key].button_pressed = bool(value)

func connect_signals():
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	resolution_option.item_selected.connect(_on_resolution_selected)

	shadow_toggle.toggled.connect(_on_shadows_toggled)
	gameplay_gi_toggle.toggled.connect(_on_gi_toggled)
	# --- Load the real saved settings from file ---
	var real_settings = SettingsManager.get_saved_file_settings()

	# --- Apply real settings to GUI ---
	var internal_sense = real_settings["gameplay"]["mouse_sensitivity"]
	gameplay_mouse_sensitivity_slider.value = internal_sense
	gameplay_mouse_sensitivity_label.text = str(internal_sense * 4.0) # Multiply for display
	fullscreen_checkbox.button_pressed = real_settings["video"]["fullscreen"]
	borderless_toggle.button_pressed = real_settings["video"]["borderless"]
	vsync_toggle.button_pressed = real_settings["graphics"]["vsync"]
	gameplay_disable_shader.button_pressed = real_settings["gameplay"]["disable_shader"]

	for key in toggles.keys():
		var section = key.get_slice("/", 0)
		var name = key.get_slice("/", 1)

		# Check if the section and name exist in real_settings
		if real_settings.has(section) and real_settings[section].has(name):
			var value = real_settings[section][name]

			toggles[key].button_pressed = bool(value)
		else:
			print("Warning: Missing setting %s/%s when applying to GUI" % [section, name])


func _on_resolution_selected(index: int):
	working_settings["video"]["resolution"] = SettingsManager.resolutions[index]
	SettingsManager.settings = working_settings.duplicate(true)
	SettingsManager.apply_settings()

func _on_fullscreen_toggled(toggled_on: bool):
	working_settings["video"]["fullscreen"] = toggled_on
	SettingsManager.settings = working_settings.duplicate(true)
	SettingsManager.apply_settings()
	_update_borderless_visibility()

func _on_shadows_toggled(toggled_on: bool):
	EventBus.emit_signal("toggle_shadow_on_dynamic_objects", toggled_on)
	working_settings["graphics"]["shadows"] = toggled_on

func _on_gi_toggled(toggled_on: bool):
	var we_list = get_tree().get_nodes_in_group("worldEnvironment")
	if we_list.is_empty():
		return
	var we: WorldEnvironment = we_list[0]
	if we.environment:
		we.environment.sdfgi_enabled = toggled_on
	working_settings["graphics"]["gi"] = toggled_on

func _on_apply_pressed():
	for key in toggles.keys():
		var section = key.get_slice("/", 0)
		var name = key.get_slice("/", 1)
		var value = toggles[key].button_pressed
		working_settings[section][name] = value
		
	# Special case for borderless
	if fullscreen_checkbox.button_pressed:
		working_settings["video"]["borderless"] = borderless_toggle.button_pressed
	else:
		working_settings["video"]["borderless"] = false
		borderless_toggle.button_pressed = false

	# --- ADD THIS: Save disable_shader manually ---
	for child in get_tree().get_nodes_in_group("Player_shader"):
		if child.visible == true:
			working_settings["gameplay"]["disable_shader"] = false
			break
		else:
			working_settings["gameplay"]["disable_shader"] = true

	# Save
	SettingsManager.settings = working_settings.duplicate(true)
	SettingsManager.apply_settings()
	SettingsManager.save_settings()
	print("Settings applied and saved.")
	hide()
	hide_preview_scene()
	pause_menu._reset_button_alpha()

func show_preview_scene():
	preview_scene.show()
func hide_preview_scene():
	preview_scene.hide()

func _on_exit_pressed():
	# Revert working settings to the last saved file, not memory
	working_settings = SettingsManager.get_saved_file_settings()
	apply_working_settings_to_ui()
	SettingsManager.settings = working_settings.duplicate(true)
	SettingsManager.apply_settings()
	hide()
	pause_menu._reset_button_alpha()
	hide_preview_scene()


func _update_borderless_visibility():
	var is_fullscreen = fullscreen_checkbox.button_pressed
	borderless_toggle.visible = true # Always visible
	borderless_toggle.disabled = not is_fullscreen # Only clickable if fullscreen


func _on_fish_eye_value_changed(value):
	gameplay_fisheye_label.text = str(value)
	shader.set_shader_parameter("FISHEYE_AMOUNT", value)

func _on_sharpening_2_value_changed(value):
	gameplay_sharpening_label.text = str(value)
	shader.set_shader_parameter("SHARPENING", value)


func _on_Fisheye_Text_Submitted(text):
	var num = float(text)
	num = clamp(num, graphics_fisheye_slider.min_value, graphics_fisheye_slider.max_value) # Stay in slider range
	graphics_fisheye_slider.value = num


func _on_sharpening_text_submitted(text):
	var num = float(text)
	num = clamp(num, graphics_sharpening_slider.min_value, graphics_sharpening_slider.max_value) # Stay in slider range
	graphics_sharpening_slider.value = num


func _on_disable_shader_effect_pressed():
	for child in get_tree().get_nodes_in_group("Player_shader"):
		if child.visible == false:
			child.visible = true
		else:
			child.visible = false
	# Save what the new result is


func _on_vsync_pressed():
	var settings = SettingsManager.get_saved_file_settings()
	if settings["graphics"]["vsync"] == false:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)


func _on_mouse_sensativity_value_changed(value):
	var display_value = value * 4.0
	gameplay_mouse_sensitivity_label.text = str(display_value)
	EventBus.emit_signal("mouse_sense_change", value)
	working_settings["gameplay"]["mouse_sensitivity"] = value


func _on_mouse_sense_text_submitted(value):
	var display_value = value.to_float() * 4.0
	gameplay_mouse_sensitivity_label.text = str(display_value)
	EventBus.emit_signal("mouse_sense_change", value)
	working_settings["gameplay"]["mouse_sensitivity"] = value
