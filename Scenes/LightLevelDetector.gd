extends Node3D

@export var active: bool = true
@export var player: PlayerMachine
@export var camera: Camera3D
@export var timer: Timer
@onready var closelight: SpotLight3D = $SpotLight3D
@onready var we : WorldEnvironment = get_tree().root.get_node("world").find_child("WorldEnvironment")
@onready var groundlight: SpotLight3D = $"../../../../Groundlight"

#Debugging
var lightvalue: float = 0
var in_darkness: bool = false
var starttimer: Timer

# THIS SCRIPT IS KIND OF HEAVY, PROBABLY RELATED TO LUMINANCE CALCULATION, CURRENT REMEDY; ONLY RUNS ONCE EVER 0.75 (or whatver refresh-timer is set to)
# Called when the node enters the scene tree for the first time.
func _ready():
	timer = find_child("Refresh Timer")
	lightvalue = 1
	
func timerdown():
	if(active):
		global_position = player.global_position + Vector3(0, 1.2, 0)
		var texture = camera.get_viewport().get_texture()
		var color = get_average_color(texture,15)
		lightvalue = color.get_luminance()
	
func _process(delta):
	if(active):
		assert(we.dark_properties != null, "There exists a world-environment node with a missing world_environment_data script. Add one immediately.")
		if(in_darkness):
			# Set the WE to brightened settings (higher contrast, dark is still dark, but a light increase in visibility)
			for key in we.dark_properties:
				we.environment[key] = lerp(we.environment[key], we.dark_properties[key], delta * 1)

			#if(lightvalue >= we.light_value):
				#in_darkness = false
			#we.environment.adjustment_saturation = lerp(we.environment.adjustment_saturation, we.properties["adjustment_saturation"] * we.saturation_darken_factor, delta * 0.85)
			#we.environment.adjustment_contrast = lerp(we.environment.adjustment_contrast, we.properties["adjustment_contrast"] * we.contrast_darken_factor, delta * 1.25)
			closelight.light_energy = lerp(closelight.light_energy, 0.08, delta * 1)
			groundlight.light_energy = lerp(groundlight.light_energy, 0.401, delta * 1)
			if(lightvalue >= we.light_value):
				in_darkness = false
		else:
			for key in we.dark_properties:
				we.environment[key] = lerp(we.environment[key], we.properties[key], delta * 1.65)
			# Set the WE to default settings (regular contrast, dark is supposed to be dark here)
			#we.environment.adjustment_contrast = lerp(we.environment.adjustment_contrast, we.properties["adjustment_contrast"], delta * 1.25)
			#we.environment.adjustment_saturation = lerp(we.environment.adjustment_saturation, we.properties["adjustment_saturation"], delta * 0.85)
			closelight.light_energy = lerp(closelight.light_energy, 0.0, delta * 1.65)
			groundlight.light_energy = lerp(groundlight.light_energy, 0.0, delta * 1.65)

			if(lightvalue <= we.dark_value):
				in_darkness = true

func get_average_color(texture: ViewportTexture, samples: int) -> Color:
	var image = texture.get_image()
	
	var total_color = Color(0, 0, 0, 0)  # Store the sum of all sampled colors
	var width = image.get_width()
	var height = image.get_height()
	
	# Determine the spacing between samples based on the number of samples
	var x_spacing = width / float(samples)
	var y_spacing = height / float(samples)
	
	# Loop over the image using evenly spaced points
	for i in range(samples):
		for j in range(samples):
			# Calculate the pixel coordinates for sampling
			var x = int(i * x_spacing)
			var y = int(j * y_spacing)
			
			# Get the color of the pixel at (x, y)
			var pixel_color = image.get_pixel(x, y)
			
			# Accumulate the total color
			total_color += pixel_color
	
	# Calculate the average color by dividing by the total number of samples
	var average_color = total_color / float(samples * samples)
	return average_color
