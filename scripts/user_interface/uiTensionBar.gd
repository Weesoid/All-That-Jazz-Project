extends Control
class_name TPBar

@onready var count_bar = $CustomCountBar
@onready var limit_bar = $LimitBar
@onready var gradient = $Gradient
# Called when the node enters the scene tree for the first time.
func _ready():
	#pass
	#CombatGlobals.tension_changed.connect(update.unbind(3))
	#count_bar.setValue(CombatGlobals.tension)
	gradient.modulate = Color.TRANSPARENT
	limit_bar.setValue(CombatGlobals.blocked_tension)
	count_bar.setValue(CombatGlobals.tension)
	CombatGlobals.tension_changed.connect(updateTension)
	CombatGlobals.blocked_tp_changed.connect(updateBlockedTension)
#	limit_bar.setValue(4-CombatGlobals.tension_limit)
	#gradient.sel

func updateTension():
	var tween = create_tween().set_ease(Tween.EASE_IN_OUT)
	count_bar.setValue(CombatGlobals.tension)
	tween.tween_property(gradient,'modulate', Color(Color.WHITE,0.15), 0.1)
	tween.tween_property(gradient,'modulate', Color.TRANSPARENT, 0.5)

func updateBlockedTension():
	#var tween = create_tween().set_ease(Tween.EASE_IN_OUT)
	limit_bar.setValue(CombatGlobals.blocked_tension)
	#tween.tween_property(gradient,'modulate', Color(Color.WHITE,0.15), 0.1)
	#tween.tween_property(gradient,'modulate', Color.TRANSPARENT, 0.5)
