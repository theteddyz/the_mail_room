extends Label

var averageFPS: int = 0
var nrToAverage: int = 0
var lowestFPS: int = 9999999
var highestFPS: int = 0
var timerBeforeCalculating: float = 0
var resetTimer: float = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var fps = Engine.get_frames_per_second()
	
	timerBeforeCalculating += _delta
	resetTimer += _delta
	var average = 0
	
	if(resetTimer > 15):
		lowestFPS = 9999999
		highestFPS = 0
		resetTimer = 0
		averageFPS = 0
		nrToAverage = 0
	if(timerBeforeCalculating > 3):
		averageFPS += fps
		nrToAverage +=1
		average = averageFPS / nrToAverage
		
		if(lowestFPS > fps):
			lowestFPS = fps
		if(highestFPS < fps):
			highestFPS = fps
		
	
	text = "FPS:"+str(fps)+"\n"+"AVERAGE:"+str(average)+"\n"+"LOWEST:"+str(lowestFPS)+"\n"+"HIGHEST:"+str(highestFPS)
