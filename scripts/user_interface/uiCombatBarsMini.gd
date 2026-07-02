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
@onready var focus_gradient = $FocusGradient
var upper_icon_original_pos
var attached_combatant: ResPlayerCombatant
var previous_value
var default_action_pos: Vector2
@export var rest_sprite: Sprite2D

func _ready():
	focus_gradient.modulate = SettingsGlobals.ui_colors['up']
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
	updateStatusEffects()

func setFocusGradient(set_to:bool):
	print('setting focal gradient of ', attached_combatant)
	focus_gradient.visible = set_to
	$FocusGradient/AnimationPlayer.play('Show')

func addStoredStatusEffect(effect):
	var texture_rect = TextureRect.new()
	texture_rect.texture = effect.texture
	texture_rect.modulate = effect.getIconColor()
	status_effects.add_child(texture_rect)

func updateStatusEffects():
	for icon in status_effects.get_children():
		icon.queue_free()
	await get_tree().process_frame
	
	for effect in attached_combatant.stored_status_effects:
		addStoredStatusEffect(CombatGlobals.loadStatusEffect(effect))

func setConnections(set_to:bool):
	if set_to:
		if !attached_combatant.health_changed.is_connected(updateBars): 
			attached_combatant.health_changed.connect(updateBars.unbind(1))
		if !attached_combatant.health_changed.is_connected(updateStrainBar): 
			attached_combatant.stat_modified.connect(updateStrainBar.unbind(2))
		if !attached_combatant.status_effect_stored.is_connected(addStoredStatusEffect):
			attached_combatant.status_effect_stored.connect(addStoredStatusEffect)
	else:
		if attached_combatant.health_changed.is_connected(updateBars): 
			attached_combatant.health_changed.disconnect(updateBars)
		if attached_combatant.stat_modified.is_connected(updateStrainBar): 
			attached_combatant.stat_modified.disconnect(updateStrainBar)
		if attached_combatant.status_effect_stored.is_connected(addStoredStatusEffect):
			attached_combatant.status_effect_stored.disconnect(addStoredStatusEffect)

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
	if attached_combatant != null and attached_combatant.isDead():
		var throbber = rest_sprite.get_node('Throbber')
		throbber.animation_player.play('Show_KO')
		throbber.show()
		$HealthBar/ProgressBarTrueValues.hide()
	elif rest_sprite.has_node('Throbber'):
		var throbber = rest_sprite.get_node('Throbber')
		throbber.hide()
		throbber.animation_player.play('RESET')
		$HealthBar/ProgressBarTrueValues.show()

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

func reset():
	for icon in status_effects.get_children():
		icon.queue_free()
	rest_sprite.texture = null
	setConnections(false)
	attached_combatant = null


func _on_character_camp_button_focus_entered():
	pass
	#get_parent().get_node('Throbber').show()

func _on_character_camp_button_focus_exited():
	pass
	#get_parent().get_node('Throbber').hide()

#func focus():
#	camp_button.grab_focus()
