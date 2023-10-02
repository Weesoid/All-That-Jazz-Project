extends ProgressBar

@onready var animator = $"../AnimationPlayer"
@onready var audio_player = $"../AudioStreamPlayer"

func _ready():
	CombatGlobals.exp_updated.connect(startProgress)
	PlayerGlobals.level_up.connect(func(): 
		await animator.animation_finished
		animator.play("Level Up")
		audio_player.stop()
		audio_player.stream = preload("res://assets/sounds/642401__robinhood76__11404-cash-score-bonus.ogg")
		audio_player.play()
		)
	animator.play("Show")

func startProgress(experience: int, required_exp: int):
	max_value = required_exp
	value = PlayerGlobals.CURRENT_EXP
	var target_value = value + experience
	while value != target_value:
		value += 1
		await get_tree().create_timer(0.02).timeout
	audio_player.stop()
	
