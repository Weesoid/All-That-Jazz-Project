extends Control
class_name TPBar

@onready var count_bar = $CustomCountBar
@onready var gradient = $Gradient
# Called when the node enters the scene tree for the first time.
func _ready():
	#pass
	#CombatGlobals.tension_changed.connect(update.unbind(3))
	#count_bar.setValue(CombatGlobals.tension)
	gradient.modulate = Color.TRANSPARENT
	update()
	#gradient.sel

func update():
	var tween = create_tween().set_ease(Tween.EASE_IN_OUT)
	count_bar.setValue(CombatGlobals.tension)
	tween.tween_property(gradient,'modulate', Color(Color.WHITE,0.15), 0.1)
	tween.tween_property(gradient,'modulate', Color.TRANSPARENT, 0.5)
