extends Node2D

var screen_size
var pad_size
var direction = Vector2(1.0,0.0)
const INITIAL_BALL_SPEED = 80
var ball_speed = INITIAL_BALL_SPEED
const PAD_SPEED = 150
const AI_SPEED = 120  # AI paddle speed
var player_using_computer:bool = false
var has_started = false
var awaiting_next_game = true
var ball_initial_pos
@onready var player = $left
@onready var ai = $right
@onready var ball = $ball
@onready var player_score_label:Label = $"../Label"
@onready var ai_score_label:Label = $"../Label2"
var player_start_pos
var ai_start_pos
var ai_score:int
var player_score:int
func _ready():
	screen_size = get_parent().size
	pad_size = player.texture.get_size()
	ball_initial_pos = ball.position
	ai_score = 0
	player_score = 0
	player_start_pos = player.position
	ai_start_pos = ai.position
	update_scores()
	set_process(true)


func _process(delta):
	if get_parent().visible:
		if player_using_computer and !awaiting_next_game:
			if not has_started:
				var start_direction_x = -1 if randf() < 0.5 else 1
				var start_direction_y = randf() * 2.0 - 1
				direction = Vector2(start_direction_x, start_direction_y).normalized()
				has_started = true
			ball.position += direction * ball_speed * delta
			var ball_pos = ball.position
			var player_rect = Rect2(player.position - pad_size*0.5,pad_size)
			var ai_rect = Rect2(ai.position - pad_size*0.5,pad_size)
			ball_pos += direction * ball_speed * delta
			if (ball_pos.y < 0 and direction.y < 0) or (ball_pos.y > screen_size.y and direction.y > 0):
				direction.y = -direction.y
			if (player_rect.has_point(ball_pos) and direction.x < 0) or (ai_rect.has_point(ball_pos) and direction.x > 0):
				direction.x = -direction.x  # Reverse X direction
				direction.y = randf()*2.0 - 1
				direction = direction.normalized()
				ball_speed *= 1.1
			if ball_pos.x < 0:
				ai_score += 1
				game_over("AI wins!")
				return
			elif ball_pos.x > screen_size.x:
				player_score += 1
				game_over("Player Wins!")
				return
			ball.position = ball_pos
			move_ai(delta)
			var player_pos = player.position
			if (player_pos.y > pad_size.y * 0.5 and Input.is_action_pressed("forward")):
				player_pos.y += -PAD_SPEED * delta
			if (player_pos.y < screen_size.y - pad_size.y * 0.5 and Input.is_action_pressed("backward")):
				player_pos.y += PAD_SPEED * delta
			player.position = player_pos

func move_ai(delta):
	var ai_pos = ai.position
	var ball_pos = ball.position
	if ai_pos.y + pad_size.y * 0.5 < ball_pos.y:
		ai_pos.y += AI_SPEED * delta  
	elif ai_pos.y + pad_size.y * 0.5 > ball_pos.y:
		ai_pos.y -= AI_SPEED * delta 
	ai_pos.y = clamp(ai_pos.y, pad_size.y * 0.5, screen_size.y - pad_size.y * 0.5)
	ai.position = ai_pos

func hide_game():
	get_parent().hide()
	awaiting_next_game = true
func start_game():
	get_parent().show()
	await get_tree().create_timer(2.0).timeout
	reset_game()

func game_over(winner_text: String):
	update_scores()
	awaiting_next_game = true  # Prevent movement during reset
	ball_speed = INITIAL_BALL_SPEED
	ball.position = ball_initial_pos
	player.position = player_start_pos
	ai.position = ai_start_pos
	await get_tree().create_timer(2.0).timeout
	reset_game()

func update_scores():
	player_score_label.text = str(player_score)
	ai_score_label.text = str(ai_score) 

func reset_game():
	awaiting_next_game = false
	has_started = false
	var start_direction_x = -1 if randf() < 0.5 else 1
	var start_direction_y = randf() * 2.0 - 1
	direction = Vector2(start_direction_x, start_direction_y).normalized()
