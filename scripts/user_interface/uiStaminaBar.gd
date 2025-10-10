extends ProgressBar

@onready var fader = $AnimationPlayer
var changing:bool=false
func _ready():
	max_value = 100.0
	min_value = 0.0

func _process(_delta):
	value = PlayerGlobals.overworld_stats['stamina']


func _on_value_changed(_value):
	if value >= max_value and changing:
		changing=false
		fader.play_backwards("Show")
	elif value < max_value and !changing:
		changing=true
		fader.play("Show")
