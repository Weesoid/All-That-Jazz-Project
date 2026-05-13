extends Node2D
class_name CombatBar

@onready var health_bar = $HealthBar
@onready var health_bar_fader = $HealthBarFader
@onready var absolute_health = $HealthBar/AbsoluteHealth
@onready var status_effects = $HealthBar/StatusEffectContainer
@onready var permanent_status_effects = $HealthBar/PermaStatusEffectContainer
#@onready var center_status_effects = $HealthBar/CenterStatusContainer
@onready var indicator_spawn_point = $Marker2D
@onready var turn_gradient = $HealthBar/TurnGradient/AnimationPlayer
@onready var pulse_gradient = $HealthBar/TurnPulser/AnimationPlayer
@onready var turn_gradient_sprite = $HealthBar/TurnGradient
@onready var pulse_gradient_sprite = $HealthBar/TurnPulser
@onready var select_target = $SelectTarget
@onready var turn_charges: CustomCountBar = $HealthBar/TurnCharges
@onready var target_clicker = $TargetClicker
@onready var combat_scene = CombatGlobals.getCombatScene()
#@onready var notches = $HealthBar/BarNotcher
@onready var resolve_bar = $HealthBar/CustomCountBar
var attached_combatant: ResCombatant
var previous_value = 0
var current_bar_value = 100
var indicator_direction:int

func _ready():
	CombatGlobals.manual_call_indicator.connect(manualCallIndicator)
	CombatGlobals.status_effect_added.connect(addStatusIcon)
	CombatGlobals.status_effect_removed.connect(removeStatusIcon)
	for effect in attached_combatant.status_effects:
		addStatusIcon(attached_combatant, effect)
	previous_value = attached_combatant.getMaxHealth()
	health_bar_fader.modulate=Color.BLACK
	indicator_direction = [-1,1].pick_random()
	#notches.threshold_percent = (100/attached_combatant.getMaxResolve())*0.01
	#print(notches.threshold_percent)
	#print(notches.)
	#notches.addNotches()
	#$HealthBar/HFlowContainer/TextureRect.modulate = SettingsGlobals.ui_colors['up']
	#$HealthBar/HFlowContainer/TextureRect2.modulate = SettingsGlobals.ui_colors['down']
	#$TextureProgressBar/ShieldCrest/AnimationPlayer.play("Show")

func _process(_delta):
	updateBars()
	if CombatGlobals.getCombatScene().active_combatant == attached_combatant:
		turn_gradient.get_parent().show()
		turn_gradient.play('Loop')
	else:
		turn_gradient.get_parent().hide()
	#if CombatGlobals.getCombatScene().target_state != 0:
	#	select_target.show()
	#else:
	#	select_target.hide()
	#if CombatGlobals.getCombatScene().ui_inspect_target.visible:
	#	absolute_health.show()
	#else:
	#	absolute_health.hide()

func updateBars():
	if !attached_combatant.isDead():
		#health_bar.show()
		#health_bar_fader.show()
		health_bar_fader.modulate=Color.WHITE
		resolve_bar.hide()
	else:
		#health_bar.hide()
		#health_bar_fader.hide()
		health_bar_fader.modulate=Color.RED
		resolve_bar.show()
	
	health_bar.max_value = int(attached_combatant.getMaxHealth())
	health_bar.value = int(attached_combatant.stat_values['health'])
	if attached_combatant.isDead():
		resolve_bar.max_value = attached_combatant.getMaxResolve()
		resolve_bar.setValue(attached_combatant.stat_values['resolve'])
	#absolute_health.text = str(health_bar.value)
	turn_charges.value = attached_combatant.turn_charges
	turn_charges.max_value = attached_combatant.max_turn_charges
#	if attached_combatant.hasStatusEffect('Knock Out'):
#		health_bar.hide()
#	else:
#		health_bar.show()

func addStatusIcon(combatant: ResCombatant, effect: ResStatusEffect):
	#if combatant == attached_combatant and effect.name == 'Guard':
	#	shield_crest.show()
	#	shield_crest.get_node("Label").text = str(effect.duration)
	if combatant != attached_combatant or effect.hide_icon:
		return
	
	var tick_down = load("res://scenes/user_interface/StatusIcon.tscn").instantiate()
	tick_down.attached_status = effect
#	if effect.name == 'Guard':
#		await get_tree().process_frame
#		center_status_effects.add_child(tick_down)
#		#center_border.show()
#		#center_border.modulate = effect.getIconColor()
#		health_bar.tint_under = effect.getIconColor()
	if effect.permanent:
		permanent_status_effects.add_child(tick_down)
	else:
		status_effects.add_icon(tick_down)
	#print('added %s to %s' % [effect, combatant])

func removeStatusIcon(combatant: ResCombatant, effect: ResStatusEffect):
	if combatant != attached_combatant:
		return
	
	var effect_container
#	if effect.name == 'Guard':
#		#center_border.hide()
#		effect_container = center_status_effects
#		health_bar.tint_under = Color.BLACK
	if effect.permanent:
		effect_container = permanent_status_effects
	else:
		effect_container = status_effects.container
	
	for icon in effect_container.get_children():
		if icon.attached_status == effect:
			effect_container.remove_child(icon)
			icon.queue_free()
			return

func _on_health_bar_value_changed(value):
	animateFaderBar(previous_value, attached_combatant.stat_values['health'])
	previous_value = value

func animateFaderBar(prev_val, value):
	if prev_val == value:
		return
	
	health_bar_fader.modulate=Color.WHITE
	health_bar_fader.max_value = attached_combatant.getMaxHealth()
	if attached_combatant.isDead():
		health_bar_fader.value = attached_combatant.getMaxHealth()
	else:
		health_bar_fader.value = prev_val
#	if prev_val > value:
#		health_bar_fader.modulate = Color.YELLOW
#	elif prev_val < value:
#		health_bar_fader.modulate = Color.GREEN
	await get_tree().create_timer(0.5).timeout
	var tween = create_tween()
	tween.tween_method(setFaderBarValue, prev_val, value, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	await tween.finished
	health_bar_fader.modulate=Color.BLACK

func setFaderBarValue(value):
	health_bar_fader.value = value


func manualCallIndicator(combatant: ResCombatant, text: String, animation: String,top_position:bool=false):
	if attached_combatant == combatant and indicator_spawn_point.visible and combat_scene.isCombatValid():
		var range = 24
		var indicator = load("res://scenes/user_interface/Indicator.tscn").instantiate()
		var final_pos:Vector2
		
		if top_position:
			final_pos = Vector2(0,-range)
		else:
			final_pos = Vector2(indicator_direction*range,randf_range(-range,range))
		
		indicator.modulate = Color.TRANSPARENT
		indicator_spawn_point.add_child(indicator)
		if top_position:
			indicator.global_position += final_pos
		indicator.modulate = Color.WHITE
		indicator.playAnimation(
			indicator.global_position+final_pos,
			text, 
			animation
			)
		indicator_direction *= -1

func getIndicatorCount():
	return indicator_spawn_point.get_children().filter(func(child): return child is Indicator).size()

func setBarVisibility(set_to:bool):
	if set_to:
		create_tween().tween_property(health_bar_fader, 'self_modulate',Color.WHITE,0.22)
		create_tween().tween_property(health_bar, 'modulate',Color.WHITE,0.22)
		#modulate = Color.WHITE
		#health_bar_fader.modulate = Color.WHITE
		#health_bar.modulate = Color.WHITE
	else:
		create_tween().tween_property(health_bar_fader, 'self_modulate',Color.TRANSPARENT,0.22)
		create_tween().tween_property(health_bar, 'modulate',Color.TRANSPARENT,0.22)
		#modulate = Color.TRANSPARENT
		#health_bar_fader.modulate = Color.TRANSPARENT
		#health_bar.modulate = Color.TRANSPARENT

func enableClicker():
	target_clicker.show()

func disableClicker():
	target_clicker.hide()

func _on_target_clicker_pressed():
	if combat_scene.target_state == combat_scene.TargetState.SINGLE:
		combat_scene.target_combatant = attached_combatant
		OverworldGlobals.playSound("56243__qk__latch_01.ogg")
	combat_scene.target_selected.emit()
	combat_scene.removeTargetButtons()

func _on_target_clicker_mouse_entered():
	OverworldGlobals.playSound("342694__spacejoe__lock-2-remove-key-2.ogg")
	combat_scene.targetCombatant(attached_combatant)

func _on_target_clicker_focus_entered():
	OverworldGlobals.playSound("342694__spacejoe__lock-2-remove-key-2.ogg")
	combat_scene.targetCombatant(attached_combatant)

func _on_tree_exiting():
	if !is_queued_for_deletion():
		return
	
	for i in range(status_effects.get_child_count()-1,-1,-1):
		print(status_effects)
		var effect_icon = status_effects.get_children()[i]
		removeStatusIcon(attached_combatant, effect_icon.attached_status)
	
	for i in range(permanent_status_effects.get_child_count()-1,-1,-1):
		print(permanent_status_effects)
		var effect_icon = permanent_status_effects.get_children()[i]
		removeStatusIcon(attached_combatant, effect_icon.attached_status)

func setStatusVisibility(set_to:bool):
	if set_to:
		create_tween().tween_property(status_effects,'modulate',Color.WHITE,0.25)
		create_tween().tween_property(permanent_status_effects,'modulate',Color.WHITE,0.25)
	else:
		create_tween().tween_property(status_effects,'modulate',Color.TRANSPARENT,0.25)
		create_tween().tween_property(permanent_status_effects,'modulate',Color.TRANSPARENT,0.25)

func _on_tree_exited():
	pass # Replace with function body.
