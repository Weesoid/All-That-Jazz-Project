extends TextureProgressBar

@export var melee_timer: Timer
var pulsing=false

func _ready():
	modulate = Color.TRANSPARENT
	value = 0

func start():
	value = 0
	self_modulate = Color(Color.WHITE,0.5)
	var tween = create_tween().set_parallel()
	tween.finished.connect(tween.kill)
	tween.tween_property(self,'modulate',Color.WHITE,0.25)
	tween.tween_property(self,'value',max_value,melee_timer.wait_time)
	await tween.finished
	
	var fade_tween = create_tween()
	fade_tween.finished.connect(fade_tween.kill)
	fade_tween.tween_property(self,'self_modulate',Color(Color.WHITE, 1.0),0.15)
	fade_tween.tween_interval(0.2)
	fade_tween.tween_property(self,'modulate',Color.TRANSPARENT,0.25)

func pulse(color:Color):
	if pulsing:
		return
	
	pulsing=true
	var pulse_tween = create_tween()
	pulse_tween.finished.connect(
		func():
			pulse_tween.kill()
			pulsing=false
			)
	pulse_tween.tween_property(self, 'tint_over', color, 0.25)
	pulse_tween.tween_property(self, 'tint_over', Color.BLACK, 0.5)

func canShow():
	return !OverworldGlobals.player.melee_cooldown.is_stopped()
