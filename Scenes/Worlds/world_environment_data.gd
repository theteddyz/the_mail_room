extends WorldEnvironment

# Filled with the starting properties for this World_Environment node
var properties

@export var light_value = 0.069
@export var dark_value = 0.035
@export var contrast_darken_factor = 1.2
@export var saturation_darken_factor = 0.7

func _ready():
	properties = resource_to_dict(get_environment())
	GameManager.player_reference.get_node("Neck").get_node("Head").get_node("HeadbopRoot").get_node("LightLevelDetection").we = self

func resource_to_dict(resource: Resource) -> Dictionary:
	var dict = {}
	for property_name in resource.get_property_list():
		dict[property_name.name] = resource.get(property_name.name)
	return dict
