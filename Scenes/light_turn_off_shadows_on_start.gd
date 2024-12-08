extends OmniLight3D
var _range
var _energy
@onready var shadow_property = {
	"bias": shadow_bias,
	"normal_bias": shadow_normal_bias,
	"reverse_cull_face": shadow_reverse_cull_face,
	"transmittance_bias": shadow_transmittance_bias,
	"opacity": shadow_opacity,
	"blur": shadow_blur,
	"distance_fade_shadow": distance_fade_shadow
}

# Called when the node enters the scene tree for the first time.
func _ready():
	_range = omni_range
	_energy = light_energy
	omni_range = 0
	light_energy = 0
	visible = false
	if !self.is_in_group("alwaysshadow"):
		shadow_enabled = false


func _on_visible_on_screen_enabler_3d_screen_exited() -> void:
	#print("OFF")
	omni_range = 0
	light_energy = 0
	visible = false


func _on_visible_on_screen_enabler_3d_screen_entered() -> void:
	#print("ON")
	omni_range = _range
	light_energy = _energy
	visible = true
