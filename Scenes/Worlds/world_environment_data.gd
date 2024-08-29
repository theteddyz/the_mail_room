extends WorldEnvironment

var properties

func _ready():
	properties = resource_to_dict(get_environment())

func resource_to_dict(resource: Resource) -> Dictionary:
	var dict = {}
	for property_name in resource.get_property_list():
		dict[property_name.name] = resource.get(property_name.name)
	return dict
	
#func dict_to_resource(dict: Dictionary):
	#var e = get_environment()
	#for property_name in e:
		#e.get(property_name) = dict[property_name]
	#return dict
