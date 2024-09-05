extends Node3D

@export var player: PlayerMachine
@export var camera: Camera3D
@export var timer: Timer
@export var closelight: SpotLight3D
@onready var we : WorldEnvironment = get_tree().root.get_node("world").find_child("WorldEnvironment")

#Debugging
var lightvalue: float = 0
var darken: bool = false
var starttimer: Timer

# THIS SCRIPT IS KIND OF HEAVY, PROBABLY RELATED TO LUMINANCE CALCULATION, CURRENT REMEDY; ONLY RUNS ONCE EVER 0.75 (or whatver refresh-timer is set to)
# Called when the node enters the scene tree for the first time.
func _ready():
	timer = find_child("Refresh Timer")
	lightvalue = 1
	
func timerdown():
	global_position = player.global_position + Vector3(0, 1.2, 0)
	var texture = camera.get_viewport().get_texture()
	var color = get_average_color(texture)
	lightvalue = color.get_luminance()

func _process(delta):
	if we != null and we.properties != null:
		if(darken):			
			we.environment.adjustment_saturation = lerp(we.environment.adjustment_saturation, we.properties["adjustment_saturation"] * we.saturation_darken_factor, delta * 0.85)
			we.environment.adjustment_contrast = lerp(we.environment.adjustment_contrast, we.properties["adjustment_contrast"] * we.contrast_darken_factor, delta * 1.25)
			closelight.light_energy = lerp(closelight.light_energy, 0.82, delta * 0.85)
			if(lightvalue >= we.light_value):
				darken = false
		else:
			we.environment.adjustment_contrast = lerp(we.environment.adjustment_contrast, we.properties["adjustment_contrast"], delta * 1.25)
			we.environment.adjustment_saturation = lerp(we.environment.adjustment_saturation, we.properties["adjustment_saturation"], delta * 0.85)
			closelight.light_energy = lerp(closelight.light_energy, 0.0, delta * 0.85)
			if(lightvalue <= we.dark_value):
				darken = true

func get_average_color(texture: ViewportTexture):
	var image = texture.get_image()
	image.resize(1, 1, Image.INTERPOLATE_LANCZOS)
	return image.get_pixel(0, 0)
