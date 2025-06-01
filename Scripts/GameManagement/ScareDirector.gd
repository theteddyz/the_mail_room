extends Node

# Globally useful Scare-ish related signals

# Emitted on any package delivery on any floor
signal package_delivered(package_num:int)

# Emitted when any "monster"-grouped node is in plHayers' viewcone
signal monster_seen(is_seen:bool)

#  Emitted when a scare is activated
signal scare_activated(scare_index: int)

# Emitted on a keypickup
signal key_pickedup(key_num:int)

# Emitted on a usb-pickup
signal usb_pickup(usb_index:int)

# Emitted on any interacted grabbable
signal grabbable(name: String)

# Emitted on high-alert moments such as chases or "scripted events"
signal enable_intensity_flag()

# Emitted when a high-alert moment is supposed to end
signal disable_intensity_flag()

var fear_factor := 0.0
var _max_fear := 100.0

func _ready():
	connect("monster_seen", _monster_seen_log)
	
func _monster_seen_log(str: bool):
	print("MONSTER SEEN: ", str)
	
func update_fear_factor(_distance: float, _delta: float, fear_distance_limit: float):
	if _distance > fear_distance_limit:
		#todo we need to lower the fearfactor
		fear_factor -= _delta * 4.2
	else:
		# Calculate how much the distance is closed in percentage (0 = farthest, 1 = closest)
		var _percentage_of_max_distance = 1.0 - ((_distance - 9.7) / (fear_distance_limit - 9.7))
		_percentage_of_max_distance = clamp(_percentage_of_max_distance, 0.0, 1.0)
		# Interpolate a scaling factor for the fear increase (1 = slowest increase, 10 = fastest)
		var _increment_factor = lerp(1.0, 10.0, _percentage_of_max_distance)
		# Increase the fear factor with the calculated multiplier
		fear_factor += _delta * _increment_factor
	# Clamp the value because we're not batshit crazy
	fear_factor = clamp(fear_factor, 0, 100)
