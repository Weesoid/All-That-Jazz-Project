extends ProgressBar

func _ready():
	CombatGlobals.exp_updated.connect(startProgress)

func startProgress(experience: int, required_exp: int):
	max_value = required_exp
	value = PlayerGlobals.CURRENT_EXP
	var target_value = value + experience
	while value != target_value:
		value += 1
		await get_tree().create_timer(0.01).timeout
