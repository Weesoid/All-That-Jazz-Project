extends Control
class_name CombatBarsMini

@onready var fader_bar = $HealthBarFader
@onready var fader_animator = $HealthBarFader/AnimationPlayer
@onready var health_bar = $HealthBar
@onready var status_effects = $HealthBar/PermaStatusEffectContainer
@onready var prompts = $Marker2D
@onready var health_bar_fader = $HealthBarFader
@onready var strain_bar = $StrainBar
@onready var camp_button = $CharacterCampButton
var attached_combatant: ResPlayerCombatant
var previous_value
var default_action_pos: Vector2

func _ready():
	CombatGlobals.manual_call_indicator.connect(manualCallIndicator)
	#camp_button.item_received.connect(updateStrainBar)
	strain_bar.max_value = PlayerGlobals.strain_cap
	#updateStatusEffects()

func setCombatant(combatant:ResPlayerCombatant):
	if !combatant.initialized:
		combatant.initializeCombatant(false)
	attached_combatant = combatant
	previous_value = attached_combatant.stat_values['health']
	camp_button.combatant = combatant
	updateBars()
	#updateStatusEffects()

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
			animation
			)
		#indicator_direction *= -1

func _process(_delta):
	if attached_combatant == null:
		return
	updateBars()

func updateBars():
	health_bar.max_value = int(attached_combatant.base_stat_values['health'])
	health_bar.value = int(attached_combatant.stat_values['health'])

#func updateStatusEffects():
#	if attached_combatant == null:
#		return
#	for linger_effect in attached_combatant.lingering_effects:
#		if added_lingers.has(linger_effect):
#			continue
#		if linger_effect.contains('linger|'):
#			linger_effect = linger_effect.split('|')[1].replace(' ','')
#
#		status_effects.add_child(OverworldGlobals.createStatusEffectIcon(linger_effect,TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL))
#		added_lingers.append(linger_effect)

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

func _on_strain_bar_value_changed(value):
	pass
#	if value > 0:
#		fadeStrainBar(Color.WHITE)
#	elif value <= 0:
#		fadeStrainBar(Color.TRANSPARENT)
