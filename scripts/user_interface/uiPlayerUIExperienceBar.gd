extends Control

@onready var exp_bar = $ExperienceBar
@onready var level_gradient = $LevelGradient
@onready var linger_timer = $LingerTimer
var exp_bar_positions = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	exp_bar_positions['visible'] = exp_bar.position
	exp_bar_positions['hidden'] = exp_bar.position+Vector2(0,-8)
	exp_bar.exp_bar_filled.connect(doLevelUpAnimation)
	level_gradient.self_modulate = Color.TRANSPARENT
	exp_bar.modulate = Color.TRANSPARENT
	PlayerGlobals.experience_added.connect(func(_arg): showSelf())
	#print(exp_bar.position)

func doLevelUpAnimation():
	#linger_timer.stop()
	var tween = get_tree().create_tween()
	tween.tween_property(level_gradient, 'self_modulate', Color.WHITE, 0.05)
	tween.tween_property(level_gradient, 'self_modulate', Color.TRANSPARENT, 1.5)
	await tween.finished
	linger_timer.start()

func showSelf():
	var tween = get_tree().create_tween().set_parallel()
	linger_timer.stop()
	exp_bar.position = exp_bar_positions['hidden']
	tween.tween_property(exp_bar, 'position', exp_bar_positions['visible'], 0.25)
	tween.tween_property(exp_bar, 'modulate', Color.WHITE, 0.2)
	await tween.finished
	linger_timer.start()

func _on_linger_timer_timeout():
	var tween = get_tree().create_tween().set_parallel()
	tween.tween_property(exp_bar, 'position', exp_bar_positions['hidden'], 0.25)
	tween.tween_property(exp_bar, 'modulate', Color.TRANSPARENT, 0.2)
