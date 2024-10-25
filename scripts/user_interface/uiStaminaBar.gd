extends ProgressBar

func _ready():
	max_value = 100.0
	min_value = 0.0

func _process(_delta):
	value = PlayerGlobals.overworld_stats['stamina']
	if value < 100:
		show()
	else:
		hide()
