extends Label

var averageFPS: int = 0
var nrToAverage: int = 0
var lowestFPS: int = 9999999
var highestFPS: int = 0
var timerBeforeCalculating: float = 0
var resetTimer: float = 0
var drawCallTimer: float = 0
var drawCalls = 0
var drawCallAverage: int = 0
var drawCallNrToAverage: int = 0
var drawCallHighest: int = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var fps = Engine.get_frames_per_second()
	
	
	timerBeforeCalculating += _delta
	resetTimer += _delta
	drawCallTimer += _delta
	var average = 0
	

	drawCalls = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var averageDrawcall = 0
	
	var memory =  Performance.get_monitor(Performance.MEMORY_STATIC)
	
	if(resetTimer > 15):
		lowestFPS = 9999999
		highestFPS = 0
		resetTimer = 0
		averageFPS = 0
		nrToAverage = 0
		drawCallHighest = 0
		averageDrawcall = 0
	if(timerBeforeCalculating > 3):
		averageFPS += fps
		nrToAverage +=1
		average = averageFPS / nrToAverage
		
		drawCallAverage += drawCalls
		drawCallNrToAverage += 1
		averageDrawcall = drawCallAverage / drawCallNrToAverage
		
		if(lowestFPS > fps):
			lowestFPS = fps
		if(highestFPS < fps):
			highestFPS = fps
		if(drawCalls > drawCallHighest):
			drawCallHighest = drawCalls
		
	
	text = "FPS: "+str(fps)+"
	FPS AVG: "+str(average)+"
	FPS HIGH: "+str(highestFPS)+"
	FPS LOW: "+str(lowestFPS)+"
	DRAWC: "+str(drawCalls)+"
	DRAWC AVG: "+str(averageDrawcall)+"
	DRAWC HIGH: "+str(drawCallHighest)+"
	MEMORY: "+str(snapped((memory / 1000000), 0))+" MB"
