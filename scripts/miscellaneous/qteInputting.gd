extends Node2D

@onready var container = $Container
@onready var ding_sound = $AudioStreamPlayer2D
@onready var timer = $Timer
@onready var time_bar = $ProgressBar

var inputs: Array[String]

var hit = 0
var points = 0
var max_points = 3
var input_count

func _ready():
	input_count = max_points * 3
	timer.start(input_count / 3)
	time_bar.max_value = timer.wait_time
	generateInputs()
	print(inputs)

func _process(_delta):
	time_bar.value = timer.time_left

func generateInputs():
	var possible_inputs = ['ui_left', 'ui_right', 'ui_up', 'ui_down']
	for i in range(input_count):
		randomize()
		inputs.append(possible_inputs.pick_random())
	displayInputs()
		

func displayInputs():
	if inputs.is_empty():
		return
	
	for child in container.get_children():
		child.queue_free()
	
	for i in range(3):
		var icon = TextureRect.new()
		match inputs[i]:
			'ui_left': icon.texture = preload("res://assets/icons/arrow_left.png")
			'ui_right': icon.texture = preload("res://assets/icons/arrow_right.png")
			'ui_down': icon.texture = preload("res://assets/icons/arrow_down.png")
			'ui_up': icon.texture = preload("res://assets/icons/arrow_up.png")
		if i != 0:
			icon.self_modulate.a = 0.25
		else:
			icon.self_modulate.a = 1
		container.add_child(icon)
		
	

func _unhandled_key_input(_event):
	if Input.is_action_just_pressed(inputs.front()):
		inputs.pop_front()
		hit += 1
		container.get_child(hit-1).self_modulate.a = 0
		if hit % 3 == 0:
			points += 1
			timer.start(timer.time_left + 1.0)
			displayInputs()
			hit = 0
		ding_sound.pitch_scale += (0.025 * points)
		ding_sound.play()
		if points == max_points:
			CombatGlobals.qte_finished.emit()
		container.get_child(hit).self_modulate.a = 1.0
	elif Input.is_action_just_pressed('ui_up') or Input.is_action_just_pressed('ui_down') or Input.is_action_just_pressed('ui_left') or Input.is_action_just_pressed('ui_right'):
		timer.start(timer.time_left - 0.25)
		if timer.wait_time < 1.0:
			CombatGlobals.qte_finished.emit()

func _on_timer_timeout():
	print('timeout!')
	CombatGlobals.qte_finished.emit()
