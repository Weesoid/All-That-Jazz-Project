extends Control
class_name CombatBarsMini

@onready var fader_bar = $HealthBarFader
@onready var fader_animator = $HealthBarFader/AnimationPlayer
@onready var health_bar = $HealthBar
@onready var status_effects = $HealthBar/PermaStatusEffectContainer
@onready var prompts = $Marker2D
@onready var health_bar_fader = $HealthBarFader
@onready var strain_bar = $StrainBar
#@onready var camp_button = $CharacterCampButton
@onready var upper_icon = $Watchmark
var upper_icon_original_pos
var attached_combatant: ResPlayerCombatant
var previous_value
var default_action_pos: Vector2

func _ready():
	CombatGlobals.manual_call_indicator.connect(manualCallIndicator)
	upper_icon_original_pos = upper_icon.position
	strain_bar.setMax(PlayerGlobals.strain_cap)# = 
	setWatchmark(false)
	#OverworldGlobals.end_camp.connect(setConnections.bind(false))
	#updateStatusEffects()

func setCombatant(combatant:ResPlayerCombatant):
	if !combatant.initialized:
		combatant.initializeCombatant(false)
	attached_combatant = combatant
	setConnections(true)
	previous_value = attached_combatant.stat_values['health']
	#camp_button.combatant = combatant
	updateBars()
	updateStrainBar()
	#updateStatusEffects()

func setConnections(set_to:bool):
	if set_to:
		if !attached_combatant.health_changed.is_connected(updateBars): 
			attached_combatant.health_changed.connect(updateBars.unbind(1))
		if !attached_combatant.health_changed.is_connected(updateStrainBar): 
			attached_combatant.stat_modified.connect(updateStrainBar.unbind(2))
	else:
		if attached_combatant.health_changed.is_connected(updateBars): 
			attached_combatant.health_changed.disconnect(updateBars)
		if attached_combatant.stat_modified.is_connected(updateStrainBar): 
			attached_combatant.stat_modified.disconnect(updateStrainBar)

func manualCallIndicator(combatant: ResCombatant, text: String, animation: String,top_position:bool=false):
	if attached_combatant == combatant and prompts.visible:
		var range = 8
		var indicator = load("res://scenes/user_interface/Indicator.tscn").instantiate()
		var final_pos:Vector2
		
		if top_position:
			final_pos = Vector2(0,-range)
		else:
			final_pos = Vector2(range,randf_range(-range,range))
		
		indicator.modulate = Color.TRANSPARENT
		prompts.add_child(indicator)
		if top_position:
			indicator.global_position += final_pos
		indicator.modulate = Color.WHITE
		indicator.playAnimation(
			indicator.global_position+final_pos,
			text, 
			animation,
			2
			)

func updateBars():
	health_bar.max_value = int(attached_combatant.base_stat_values['health'])
	health_bar.value = int(attached_combatant.stat_values['health'])

func highlightCombatant():
	health_bar.get_node('ProgressBarTrueValues').show()

func stopHighlight():
	health_bar.get_node('ProgressBarTrueValues').hide()

func animateFaderBar(prev_val, value):
	if prev_val == value:
		return
	
	health_bar_fader.max_value = attached_combatant.getMaxHealth()
	health_bar_fader.value = prev_val
	if prev_val > value:
		health_bar_fader.modulate = Color.YELLOW
	elif prev_val < value:
		health_bar_fader.modulate = Color.GREEN
	health_bar_fader.modulate = Color.ORANGE
	await get_tree().create_timer(0.5).timeout
	var tween = create_tween().set_parallel(true)
	tween.tween_method(setFaderBarValue, prev_val, value, 0.3).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(health_bar_fader, 'modulate', Color.BLACK, 0.4)

func setFaderBarValue(value):
	health_bar_fader.value = value

func _on_health_bar_value_changed(value):
	animateFaderBar(previous_value, attached_combatant.stat_values['health'])
	previous_value = health_bar.value

func updateStrainBar():
	strain_bar.setValue(attached_combatant.stat_values['strain'])
	if attached_combatant.stat_values['strain'] > 0:
		fadeStrainBar(Color.WHITE)
	else:
		fadeStrainBar(Color.TRANSPARENT)

func fadeStrainBar(fade_to: Color):
	create_tween().tween_property(strain_bar, 'modulate',fade_to,0.25)

func setWatchmark(set_to:bool):
	var tween = create_tween().set_parallel()
	var offscreen_offset = Vector2(0,-8)
	if set_to:
		tween.tween_property(upper_icon, 'position', upper_icon_original_pos,0.25)
		tween.tween_property(upper_icon, 'modulate', Color.WHITE,0.2)
	else:
		tween.tween_property(upper_icon, 'position', upper_icon_original_pos+offscreen_offset,0.25)
		tween.tween_property(upper_icon, 'modulate', Color.TRANSPARENT,0.2)

func _on_character_camp_button_focus_entered():
	pass
	#get_parent().get_node('Throbber').show()

func _on_character_camp_button_focus_exited():
	pass
	#get_parent().get_node('Throbber').hide()

#func focus():
#	camp_button.grab_focus()
