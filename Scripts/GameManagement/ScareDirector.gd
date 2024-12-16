extends Node

# Globally useful Scare-ish related signals

# Emitted on any package delivery on any floor
signal package_delivered(package_num:int)

# Emitted when any "monster"-grouped node is in players' viewcone
signal monster_seen(is_seen:bool)

#  Emitted when a scare is activated
signal scare_activated(scare_index: int)

# Emitted on a keypickup
signal key_pickedup(key_num:int)

# Emitted on any interacted grabbable
signal grabbable(name: String)

# Emitted on high-alert moments such as chases or "scripted events"
signal enable_intensity_flag()

# Emitted when a high-alert moment is supposed to end
signal disable_intensity_flag()

func _ready():
	connect("monster_seen", _monster_seen_log)
	
func _monster_seen_log(str: bool):
	print("MONSTER SEEN: ", str)
