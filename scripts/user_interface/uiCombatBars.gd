extends Node2D
class_name CombatBar

@onready var health_bar = $HealthBar
@onready var health_bar_fader = $HealthBarFader
@onready var health_bar_fader_animator = $HealthBarFader/AnimationPlayer
@onready var absolute_health = $HealthBar/AbsoluteHealth
@onready var status_effects = $HealthBar/StatusEffectContainer
@onready var permanent_status_effects = $HealthBar/PermaStatusEffectContainer
@onready var indicator = $Indicator
@onready var indicator_label = $Indicator/Label
@onready var indicator_animator = $Indicator/AnimationPlayer
@onready var secondary_prompts = $Marker2D
@onready var turn_gradient = $HealthBar/TurnGradient/AnimationPlayer
@onready var pulse_gradient = $HealthBar/TurnPulser/AnimationPlayer
@onready var turn_gradient_sprite = $HealthBar/TurnGradient
@onready var pulse_gradient_sprite = $HealthBar/TurnPulser
@onready var select_target = $SelectTarget
@onready var turn_charges: CustomCountBar = $HealthBar/TurnCharges
@onready var target_clicker = $TargetClicker
var indicator_animation = "Show"
var attached_combatant: ResCombatant # Attaching this seems to cause the leak, isolate
var previous_value = 0
var current_bar_value = 100

func _ready():
	CombatGlobals.manual_call_indicator.connect(manualCallIndicator)
	CombatGlobals.status_effect_added.connect(addStatusIcon)
	CombatGlobals.status_effect_removed.connect(removeStatusIcon)
	for effect in attached_combatant.status_effects:
		addStatusIcon(attached_combatant, effect)
	previous_value = attached_combatant.getMaxHealth()

func _process(_delta):
	if CombatGlobals.getCombatScene().combat_result != -1:
		queue_free()
	
	updateBars()
	if CombatGlobals.getCombatScene().active_combatant == attached_combatant:
		turn_gradient.get_parent().show()
		turn_gradient.play('Loop')
	else:
		turn_gradient.get_parent().hide()
	if CombatGlobals.getCombatScene().target_state != 0:
		select_target.show()
	else:
		select_target.hide()
	if CombatGlobals.getCombatScene().ui_inspect_target.visible:
		absolute_health.show()
	else:
		absolute_health.hide()

func updateBars():
	health_bar.max_value = int(attached_combatant.base_stat_values['health'])
	health_bar.value = int(attached_combatant.stat_values['health'])
	absolute_health.text = str(health_bar.value)
	turn_charges.value = attached_combatant.turn_charges
	turn_charges.max_value = attached_combatant.max_turn_charges
	if attached_combatant.hasStatusEffect('Knock Out'):
		health_bar.hide()
	else:
		health_bar.show()

func addStatusIcon(combatant: ResCombatant, effect: ResStatusEffect):
	if combatant != attached_combatant:
		return
	
	var tick_down = load("res://scenes/user_interface/StatusIcon.tscn").instantiate()
	tick_down.attached_status = effect
	if effect.permanent:
		permanent_status_effects.add_child(tick_down)
	else:
		status_effects.add_child(tick_down)
	print('added %s to %s' % [effect, combatant])

func removeStatusIcon(combatant: ResCombatant, effect: ResStatusEffect):
	if combatant != attached_combatant:
		return
	
	var effect_container
	if effect.permanent:
		effect_container = permanent_status_effects
	else:
		effect_container = status_effects
	
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
	
	health_bar_fader.max_value = attached_combatant.getMaxHealth()
	health_bar_fader.value = prev_val
	if prev_val > value:
		health_bar_fader.modulate = Color.YELLOW
	elif prev_val < value:
		health_bar_fader.modulate = Color.GREEN
	await get_tree().create_timer(0.25).timeout
	var tween = create_tween().set_parallel(true)
	tween.tween_method(setFaderBarValue, prev_val, value, 0.3)
	tween.tween_property(health_bar_fader, 'modulate', Color.BLACK, 0.4)

func setFaderBarValue(value):
	health_bar_fader.value = value


func manualCallIndicator(combatant: ResCombatant, text: String, animation: String):
	if attached_combatant == combatant and indicator.visible:
		await get_tree().process_frame
		var secondary_indicator = load("res://scenes/user_interface/SecondaryIndicator.tscn").instantiate()
		secondary_indicator.modulate = Color.TRANSPARENT
		var y_placement = 0
		#var wait = 0
		for child in secondary_prompts.get_children():
			y_placement -= 8
			#wait += 0.2
		#create_tween().tween_property(secondary_indicator,modulate)
		secondary_prompts.add_child(secondary_indicator)
		#await get_tree().create_timer(wait).timeout
		secondary_indicator.modulate = Color.WHITE
		secondary_indicator.playAnimation(indicator.global_position+Vector2(0,y_placement), text, animation)
		match animation:
			'Status_Up':
				var up_indicator = load("res://scenes/animations_quick/StatusRankUp.tscn").instantiate()
				secondary_indicator.add_child(up_indicator)
			'Status_Resisted':
				var up_indicator = load("res://scenes/animations_quick/StatusResisted.tscn").instantiate()
				secondary_indicator.add_child(up_indicator)
			'Status_Added':
				var up_indicator = load("res://scenes/animations_quick/StatusAdded.tscn").instantiate()
				secondary_indicator.add_child(up_indicator)
			'Status_Max':
				var up_indicator = load("res://scenes/animations_quick/StatusMaxed.tscn").instantiate()
				secondary_indicator.add_child(up_indicator)

func setBarVisibility(set_to:bool):
	if set_to:
		health_bar_fader.modulate = Color.WHITE
		health_bar.modulate = Color.WHITE
	else:
		health_bar_fader.modulate = Color.TRANSPARENT
		health_bar.modulate = Color.TRANSPARENT

func enableClicker():
	target_clicker.show()

func disableClicker():
	target_clicker.hide()

func _on_target_clicker_pressed():
	var combat_scene = CombatGlobals.getCombatScene()
	if combat_scene.target_state == combat_scene.TargetState.SINGLE:
		combat_scene.target_combatant = attached_combatant
		OverworldGlobals.playSound("56243__qk__latch_01.ogg")
	combat_scene.target_selected.emit()
	combat_scene.removeTargetButtons()

func _on_target_clicker_mouse_entered():
	var combat_scene = CombatGlobals.getCombatScene()
	OverworldGlobals.playSound("342694__spacejoe__lock-2-remove-key-2.ogg")
	combat_scene.targetCombatant(attached_combatant)

func _on_target_clicker_focus_entered():
	var combat_scene = CombatGlobals.getCombatScene()
	OverworldGlobals.playSound("342694__spacejoe__lock-2-remove-key-2.ogg")
	combat_scene.targetCombatant(attached_combatant)

func _on_tree_exiting():
	for i in range(status_effects.get_child_count()-1,-1,-1):
		print(status_effects)
		var effect_icon = status_effects.get_children()[i]
		removeStatusIcon(attached_combatant, effect_icon.attached_status)

	for i in range(permanent_status_effects.get_child_count()-1,-1,-1):
		print(permanent_status_effects)
		var effect_icon = permanent_status_effects.get_children()[i]
		removeStatusIcon(attached_combatant, effect_icon.attached_status)
