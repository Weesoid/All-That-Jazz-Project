extends Node

@onready var player = OverworldGlobals.getPlayer()
var active = true

func _physics_process(_delta):
	if player.stamina > 0 and active:
		player.channeling_power = true
		setInvisible()
	else:
		player.channeling_power = false
		player.toggleVoidAnimation(false)
		setVisible()

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_gambit"):
		player.toggleVoidAnimation(false)
		active = false
		player.channeling_power = false
		setVisible()

func setInvisible():
	player.stamina_regen = false
	player.stamina -= 0.5
	player.set_collision_layer_value(5, false)
	player.set_collision_mask_value(5, false)
	player.SPEED = 150
	player.sprite.modulate.a = 0.5

func setVisible():
	player.stamina_regen = true
	player.SPEED = 100
	player.set_collision_layer_value(5, true)
	player.set_collision_mask_value(5, true)
	player.sprite.modulate.a = 1
	queue_free()
