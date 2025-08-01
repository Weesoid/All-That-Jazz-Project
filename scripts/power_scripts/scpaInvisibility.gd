extends Node2D

@onready var bar = $ProgressBar
@onready var timer = $Timer
var active = true

func _physics_process(_delta):
	if OverworldGlobals.player.sprinting or OverworldGlobals.player.bow_draw_strength > 0.0:
		setVisible()
	bar.value = timer.time_left
#	if PlayerGlobals.overworld_stats['stamina']> 0 and active:
#		OverworldGlobals.player.channeling_power = true
#		setInvisible()
#	else:
#		OverworldGlobals.player.channeling_power = false
#		OverworldGlobals.player.toggleVoidAnimation(false)
#		setVisible()

func _ready():
	bar.max_value = timer.wait_time
	if PlayerGlobals.overworld_stats['stamina'] >= 50:
		PlayerGlobals.overworld_stats['stamina'] -= 50
		setInvisible()

#func _unhandled_input(_event):
#	if Input.is_action_just_pressed("ui_gambit"):
#		OverworldGlobals.player.toggleVoidAnimation(false)
#		active = false
#		OverworldGlobals.player.channeling_power = false
#		setVisible()

func setInvisible():
	OverworldGlobals.player.toggleVoidAnimation(true)
	OverworldGlobals.player.stamina_regen = false
	OverworldGlobals.player.set_collision_layer_value(5, false)
	OverworldGlobals.player.set_collision_mask_value(5, false)
	OverworldGlobals.player.sprite.modulate.a = 0.5

func setVisible():
	OverworldGlobals.player.toggleVoidAnimation(false)
	OverworldGlobals.player.stamina_regen = true
	OverworldGlobals.player.set_collision_layer_value(5, true)
	OverworldGlobals.player.set_collision_mask_value(5, true)
	OverworldGlobals.player.sprite.modulate.a = 1
	queue_free()

func _on_timer_timeout():
	setVisible()
