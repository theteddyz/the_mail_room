extends Control
@onready var progress_bar:ProgressBar = $ProgressBar
var loading  = false
var next_scene:String
var load_id = null
func load_screen(s:String) -> void:
	show()
	progress_bar.value = 0
	next_scene = s
	loading = true
	load_id = ResourceLoader.load_threaded_request(next_scene)
	return


func _process(delta):
	if loading:
		var progress = []
		var status = ResourceLoader.load_threaded_get_status(next_scene, progress)
		if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS:
			progress_bar.value = progress[0] * 100
		elif status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
			await get_tree().create_timer(2.0).timeout
			loading = false
			hide()
