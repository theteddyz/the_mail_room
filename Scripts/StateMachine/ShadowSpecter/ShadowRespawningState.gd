extends State
class_name ShadowRespawningState

var player: CharacterBody3D
var functional_timers: Array[Timer] = []

@onready var respawning_timer: Timer = get_parent().find_child("Timers").find_child("respawning_timer")


func get_class_custom(): return "ShadowRespawningState"

func _ready() -> void:
	persistent_state.scare_manager.package_order_disrupted.connect(aggro)
	player = GameManager.get_player()
	persistent_state.visible = false
	respawning_timer.start(20)
	respawning_timer.timeout.connect(respawn)

func aggro():
	persistent_state.player_errors += 1
	if persistent_state.player_errors >= 2:
		change_state.call("aggro")

func stopTimers():
	for t in functional_timers:
		t.stop()

func respawn():
	change_state.call("aggro") if persistent_state.previous_state == "ShadowChasingState" else change_state.call("teleporting")
