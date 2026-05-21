extends ProgressBar
class_name ExperienceBar

@export var show_value:bool=false
@onready var true_value = $ProgressBarTrueValues
@onready var current_level = $Level
var true_value_positions={}
signal exp_bar_filled
signal fill_finished

func _ready():
	await get_tree().process_frame
	PlayerGlobals.experience_added.connect(update)
	true_value_positions['visible'] = true_value.position
	true_value_positions['hidden'] = true_value.position+Vector2(0,-4)
	if !show_value:
		true_value.position = true_value_positions['hidden']
		true_value.modulate = Color.TRANSPARENT
	print('eggular: ', PlayerGlobals.current_exp)
	#value = PlayerGlobals.current_exp
	# FUCKING WHYYYYYYYY
	get_tree().create_tween().tween_property(self,'value',PlayerGlobals.current_exp,0)
	updateMaxLevel(false)
	#update(false)



func update(level_upped:bool):
	var end_experience = PlayerGlobals.current_exp if !level_upped else PlayerGlobals.getRequiredExp(-1)
	var value_tween = get_tree().create_tween()
	
	updateMaxLevel(level_upped)
	if !show_value: setExperienceLabelVisibility(true)
	value_tween.tween_property(self,'value',end_experience,1).set_ease(Tween.EASE_IN_OUT)
	OverworldGlobals.playSound("698992__robindouglasjohnson__modeltoy-train-set.ogg",0,1,false, value_tween.finished)
	await value_tween.finished
	if !show_value: setExperienceLabelVisibility(false)
	
	if level_upped:
		var pulse_level_tween = get_tree().create_tween()
		OverworldGlobals.playSound("494984__original_sound__cinematic-trailer-risers-1.ogg")
		updateMaxLevel(false)
		value = PlayerGlobals.current_exp
		pulse_level_tween.tween_property(current_level, 'modulate', Color.YELLOW, 0.05)
		pulse_level_tween.tween_property(current_level, 'modulate', Color.WHITE, 1.5)
		exp_bar_filled.emit()
	
	fill_finished.emit()
		#update(false)

func updateMaxLevel(level_upped:bool):
	current_level.text = str(PlayerGlobals.team_level) if !level_upped else str(PlayerGlobals.team_level-1)
	max_value = PlayerGlobals.getRequiredExp() if !level_upped else PlayerGlobals.getRequiredExp(-1)

func setExperienceLabelVisibility(set_to:bool):
	var tween = get_tree().create_tween().set_parallel()
	if set_to:
		true_value.position = true_value_positions['hidden']
		tween.tween_property(true_value, 'position', true_value_positions['visible'], 0.25)
		tween.tween_property(true_value, 'modulate', Color.WHITE, 0.2)
	else:
		tween.tween_property(true_value, 'position', true_value_positions['hidden'], 0.25)
		tween.tween_property(true_value, 'modulate', Color.TRANSPARENT, 0.2)
