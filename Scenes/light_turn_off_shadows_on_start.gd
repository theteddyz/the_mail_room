extends OmniLight3D

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
	if !self.is_in_group("alwaysshadow"):
		shadow_enabled = false
