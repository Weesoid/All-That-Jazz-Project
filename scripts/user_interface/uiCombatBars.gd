extends Node2D
class_name CombatBar

#@onready var absolute_health = $HealthBar/AbsoluteHealth
#@onready var center_status_effects = $HealthBar/CenterStatusContainer
#@onready var notches = $HealthBar/BarNotcher
@onready var health_bar = $HealthBar
@onready var health_bar_fader = $HealthBarFader
@onready var status_effects = $HealthBar/StatusEffects/StatusEffectContainer
@onready var permanent_status_effects = $HealthBar/PermaStatusEffectContainer
@onready var indicator_spawn_point = $DamageSpawnPoint
@onready var status_spawn_point = $StatusSpawnPoint
@onready var turn_gradient = $HealthBar/TurnGradient/AnimationPlayer
@onready var pulse_gradient = $HealthBar/TurnPulser/AnimationPlayer
@onready var turn_gradient_sprite = $HealthBar/TurnGradient
@onready var pulse_gradient_sprite = $HealthBar/TurnPulser
@onready var select_target = $SelectTarget
@onready var turn_charges: CustomCountBar = $HealthBar/TurnCharges
@onready var target_clicker = $TargetClicker
@onready var combat_scene = CombatGlobals.getCombatScene()
@onready var resolve_bar = $HealthBar/CustomCountBar
@onready var target_top_sprite = $TargetBorder
@onready var target_top = $TargetBorder/AnimationPlayer
@onready var target_gradient_sprite = $TargetBorder/TargetGradient
@onready var target_gradient_animator = $TargetBorder/TurnGradientAnimator
@onready var indicator_intervals = $IndicatorIntervals
@onready var stat_buff_arrow = $HealthBar/BuffIcon
@onready var stat_debuff_arrow = $HealthBar/DebuffIcon

var attached_combatant: ResCombatant
var previous_value = 0
var current_bar_value = 100
var indicator_direction:int
var indicator_queue: Array[Dictionary] = []
var indicators_running:bool=false

func _ready():
	CombatGlobals.manual_call_indicator.connect(addIndicatorToQueue)
	CombatGlobals.status_effect_added.connect(addStatusIcon)
	#CombatGlobals.status_effect_removed.connect(removeStatusIcon)
	combat_scene.active_combatant_changed.connect(showActingGradient)
	for effect in attached_combatant.status_effects:
		addStatusIcon(attached_combatant, effect)
	previous_value = attached_combatant.getMaxHealth()
	health_bar_fader.modulate=Color.BLACK
	indicator_direction = [-1,1].pick_random()
	target_top_sprite.hide()
	target_top.play("Show")
	attached_combatant.health_changed.connect(updateHealthBar.unbind(1))
	attached_combatant.resolve_changed.connect(updateResolveBar)
	updateHealthBar()
	updateResolveBar()
	animateFaderBar(0,attached_combatant.stat_values['health'])
	stat_buff_arrow.self_modulate = SettingsGlobals.ui_colors['up']
	UIGlobals.addTooltip(
		stat_buff_arrow,
		'SEX',
		CustomTooltip.AnchorPreset.TOP,
		0.2,
		true
		)
	stat_debuff_arrow.self_modulate = SettingsGlobals.ui_colors['down']

func showActingGradient(combatant:ResCombatant):
	if attached_combatant == combatant:
		turn_gradient.play("Loop")
	else:
		turn_gradient.play("RESET")

func pulseTurn(combatant:ResCombatant):
	if combatant != attached_combatant: return
	pulse_gradient_sprite.self_modulate=Color.WHITE
	pulse_gradient.play("Show")

func showTargetSelector(target_selection:Array[ResCombatant]):
	#print(attached_combatant, ': ', str(target_selection))
	if !target_selection.has(attached_combatant): return
	
	pulse_gradient_sprite.self_modulate = SettingsGlobals.ui_colors['down'] if attached_combatant is ResEnemyCombatant else SettingsGlobals.ui_colors['up']
	target_top_sprite.modulate = SettingsGlobals.ui_colors['down'] if attached_combatant is ResEnemyCombatant else SettingsGlobals.ui_colors['up']
	target_top_sprite.show()
	target_gradient_animator.play("RESET")
	#pulse_gradient.play("Show")

func hideTargetSelector():
	target_top_sprite.hide()

func showGradientHover(target):
	if target is Array and !target.has(attached_combatant):
		if target_gradient_sprite.modulate != Color.TRANSPARENT: target_gradient_animator.play_backwards("Show")
		return
	elif target is ResCombatant and target != attached_combatant: 
		if target_gradient_sprite.modulate != Color.TRANSPARENT: target_gradient_animator.play_backwards("Show")
		return
	
	target_gradient_sprite.modulate = SettingsGlobals.ui_colors['down'] if attached_combatant is ResEnemyCombatant else SettingsGlobals.ui_colors['up']
	pulse_gradient.play("Show")
	target_gradient_animator.play("Show")

#func _process(_delta):
#	updateBars()
#	if CombatGlobals.getCombatScene().active_combatant == attached_combatant:
#		turn_gradient.get_parent().show()
#		turn_gradient.play('Loop')
#	else:
#		turn_gradient.get_parent().hide()
	#if CombatGlobals.getCombatScene().target_state != 0:
	#	select_target.show()
	#else:
	#	select_target.hide()
	#if CombatGlobals.getCombatScene().ui_inspect_target.visible:
	#	absolute_health.show()
	#else:
	#	absolute_health.hide()

func updateHealthBar():
	health_bar.max_value = int(attached_combatant.getMaxHealth())
	health_bar.value = int(attached_combatant.stat_values['health'])
	turn_charges.value = attached_combatant.turn_charges
	turn_charges.max_value = attached_combatant.max_turn_charges
	if !attached_combatant.isDead():
		health_bar_fader.modulate=Color.WHITE
		resolve_bar.hide()
	else:
		health_bar_fader.modulate=Color.RED
		resolve_bar.show()
	if attached_combatant.isDead(true):
		create_tween().tween_property(self, 'modulate',Color.TRANSPARENT,0.5)
		#OverworldGlobals.showQuickAnimation("res://scenes/animations_quick/SkullKill.tscn",attached_combatant.combatant_scene)
		manualCallIndicator(attached_combatant,'[color=RED]KILLING BLOW!','Show',true)
		#await tween.finished
		return

func updateResolveBar():
	resolve_bar.setMax(attached_combatant.getMaxResolve())
	resolve_bar.setValue(attached_combatant.stat_values['resolve'])

func addStatusIcon(combatant: ResCombatant, effect: ResStatusEffect):
	if combatant != attached_combatant or effect.hide_icon or attached_combatant.isDead(true):
		return
	
	var tick_down = load("res://scenes/user_interface/StatusIcon.tscn").instantiate()
	tick_down.attached_status = effect
	if effect.permanent:
		permanent_status_effects.add_child(tick_down)
	else:
		status_effects.add_child(tick_down)

func removeStatusIcon(combatant: ResCombatant, effect: ResStatusEffect):
	if combatant != attached_combatant:
		return
	
	var effect_container
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
	await get_tree().create_timer(0.5).timeout
	var tween = create_tween()
	tween.tween_method(setFaderBarValue, prev_val, value, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	health_bar_fader.modulate=Color.BLACK

func setFaderBarValue(value):
	health_bar_fader.value = value


func addIndicatorToQueue(combatant: ResCombatant, text: String, animation: String,top_position:bool=false):
	if attached_combatant != combatant or !indicator_spawn_point.visible or !combat_scene.isCombatValid():
		return
	if !top_position:
		manualCallIndicator(combatant,text,animation,top_position)
		return
	var split_messsage = text.split('\n')
	if split_messsage.size() == 0: 
		indicator_queue.append({'combatant': combatant, 'text': text, 'animation': animation, 'top_position':top_position}) 
	else:
		for message in split_messsage:
			message = message.replace('[/color]','')
			indicator_queue.append({'combatant': combatant, 'text': message, 'animation': animation, 'top_position':top_position}) 
	
	if indicator_intervals.is_stopped():
		indicator_intervals.timeout.emit()
		indicator_intervals.start()
#func runQueue():
#	for indicator in indicator_queue:
#		manualCallIndicator(indicator['combatant'], indicator['text'], indicator['animation'], indicator['top_position'])
#		await get_tree().create_timer(0.25).timeout

func manualCallIndicator(combatant: ResCombatant, text: String, animation: String,top_position:bool=false):
	var spawnpoint = indicator_spawn_point if !top_position else status_spawn_point
	var range = 24
	var indicator = load("res://scenes/user_interface/Indicator.tscn").instantiate()
	var final_pos:Vector2 = Vector2(0,-range) if top_position else Vector2(indicator_direction*range,randf_range(-range,range))
	indicator.modulate = Color.TRANSPARENT
	spawnpoint.add_child(indicator)
	indicator.modulate = Color.WHITE
	indicator.playAnimation(
		indicator.global_position+final_pos,
		text, 
		animation
		)
	if !top_position: 
		indicator_direction *= -1

func getIndicatorCount():
	return indicator_spawn_point.get_children().filter(func(child): return child is Indicator).size()

func setBarVisibility(set_to:bool):
	if set_to:
		create_tween().tween_property(health_bar_fader, 'self_modulate',Color.WHITE,0.22)
		create_tween().tween_property(health_bar, 'modulate',Color.WHITE,0.22)
	else:
		create_tween().tween_property(health_bar_fader, 'self_modulate',Color.TRANSPARENT,0.22)
		create_tween().tween_property(health_bar, 'modulate',Color.TRANSPARENT,0.22)

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
	pass


func _on_indicator_intervals_timeout():
	if indicator_queue.size() == 0:
		return
	
	var indicator = indicator_queue.pop_front()
	manualCallIndicator(indicator['combatant'], indicator['text'], indicator['animation'], indicator['top_position'])
	indicator_intervals.start()
