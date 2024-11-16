extends Area2D

@onready var hide_cooldown = $"../HideCooldown"
@onready var hide_warmup = $"../HideWarmup"
@onready var warmup_bar = $"../HideWarmupBar"
@onready var sprite = $"../Sprite2D"

var is_hiding_player = false
var in_menu = false
var hide_success = true

func _enter_tree():
	OverworldGlobals.combat_enetered.connect(cancelHiding)
	OverworldGlobals.party_damaged.connect(cancelHiding)

func _exit_tree():
	OverworldGlobals.combat_enetered.disconnect(cancelHiding)
	OverworldGlobals.party_damaged.disconnect(cancelHiding)

func _ready():
	warmup_bar.max_value = 1.0

func _process(_delta):
	if !hide_cooldown.is_stopped():
		sprite.modulate = Color(Color.TRANSPARENT, 0.5)
	else:
		sprite.modulate = Color(Color.TRANSPARENT, 1.0)
	
	if !hide_warmup.is_stopped():
		warmup_bar.show()
		warmup_bar.value = hide_warmup.wait_time - hide_warmup.time_left
	else:
		warmup_bar.hide()

func interact():
	if hide_cooldown.is_stopped():
		OverworldGlobals.setPlayerInput(false)
		hide_warmup.start(1.0)
		await hide_warmup.timeout
		if hide_success:
			OverworldGlobals.setPlayerInput(false, true, true)
			OverworldGlobals.getPlayer().hiding = true
			OverworldGlobals.getPlayer().sprinting = false
			OverworldGlobals.moveCamera(self)
			OverworldGlobals.zoomCamera(Vector2(2.5, 2.5))
			await get_tree().create_timer(0.25).timeout
			is_hiding_player = true
		else:
			exitHiding(80.0)
	else:
		OverworldGlobals.showPlayerPrompt("Can't hide here yet!")

func cancelHiding():
	if hide_warmup.time_left != 0.0:
		hide_success = false
		hide_warmup.stop()
		hide_warmup.timeout.emit()

func _unhandled_input(_event):
	print(in_menu)
	if Input.is_action_just_pressed("ui_accept") and is_hiding_player and !in_menu:
		exitHiding(60.0, true)
	elif Input.is_action_just_pressed("ui_show_menu") and is_hiding_player:
		if !in_menu:
			OverworldGlobals.zoomCamera(Vector2(2, 2), 0.1)
			loadInterface("res://scenes/user_interface/CharacterAdjust.tscn")
			in_menu = true
		else:
			OverworldGlobals.zoomCamera(Vector2(2.5, 2.5), 0.1)
			removeInterface()
			in_menu = false

func loadInterface(path):
	var ui = load(path).instantiate()
	ui.z_index = 999
	ui.name = 'menu'
	add_child(ui)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func removeInterface():
	get_node('menu').queue_free()
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)

func exitHiding(cooldown:float=60.0, pulse:bool=false):
	OverworldGlobals.setPlayerInput(true)
	OverworldGlobals.getPlayer().hiding = false
	is_hiding_player = false
	OverworldGlobals.moveCamera(OverworldGlobals.getPlayer(), 0)
	OverworldGlobals.zoomCamera(Vector2(2, 2))
	hide_cooldown.start(cooldown)
	hide_success = true
	if pulse:
		OverworldGlobals.addPatrollerPulse(self, 110.0, 2)
