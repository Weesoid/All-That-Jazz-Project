extends Node

@onready var player = OverworldGlobals.getPlayer()
@onready var timer = $Timer
var active = true

func _physics_process(_delta):
	if player.sprinting or player.bow_draw_strength > 0.0:
		setVisible()
#	if PlayerGlobals.overworld_stats['stamina']> 0 and active:
#		player.channeling_power = true
#		setInvisible()
#	else:
#		player.channeling_power = false
#		player.toggleVoidAnimation(false)
#		setVisible()

func _ready():
	if PlayerGlobals.overworld_stats['stamina'] >= 50:
		PlayerGlobals.overworld_stats['stamina'] -= 50
		setInvisible()
	else:
		player.prompt.showPrompt('Not enough [color=yellow]stamina[/color].')

#func _unhandled_input(_event):
#	if Input.is_action_just_pressed("ui_gambit"):
#		player.toggleVoidAnimation(false)
#		active = false
#		player.channeling_power = false
#		setVisible()

func setInvisible():
	player.toggleVoidAnimation(true)
	player.stamina_regen = false
	player.set_collision_layer_value(5, false)
	player.set_collision_mask_value(5, false)
	player.sprite.modulate.a = 0.5

func setVisible():
	player.toggleVoidAnimation(false)
	player.stamina_regen = true
	player.set_collision_layer_value(5, true)
	player.set_collision_mask_value(5, true)
	player.sprite.modulate.a = 1
	queue_free()

func _on_timer_timeout():
	setVisible()
