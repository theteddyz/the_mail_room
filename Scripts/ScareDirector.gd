extends Node

var scareIntensity:float = 0.0
var scareThreshold:float = 10.0
var decayRate:float = 0.1
var events: Dictionary = {
	"sound_event":2.0,
	"environment_change":3.0,
	"monster_encounter":4.0
}

var scare_log: Array = []
func _ready():
	EventBus.connect("scare_event",triggeredScareEvent)

func triggeredScareEvent(event_type:String,position:Vector3):
	logScareEvent(event_type,position)
	if event_type in events:
		var eventIntensity = events[event_type]
		scareIntensity += eventIntensity
		checkScareThreshold()


func logScareEvent(eventType:String,position:Vector3):
	var scare_entry = {
		"type": eventType,
		"position": position,
		"time": Time.get_time_dict_from_system()
	}
	print(scare_entry)

func checkScareThreshold ():
	print(scareIntensity)
	if scareIntensity >= scareThreshold:
		print("SCARE THRESHOLD REACHED")
		scareIntensity = 0.0
