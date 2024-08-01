extends Node

# Globally useful Scare-ish related signals

# Emitted on any package delivery on any floor
signal package_delivered(package_num:int)

# Emitted when any "monster"-grouped node is in players' viewcone
signal monster_seen(is_seen:bool)

# Emitted on a keypickup
signal key_pickedup(key_num:int)

func _ready():
	pass
