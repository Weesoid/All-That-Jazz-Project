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
var indicator_animation = "Show"
var received_combatant: ResCombatant
var attached_combatant: ResCombatant
var previous_value = 0
var current_bar_value = 100
var first_turn = true

func _ready():
	CombatGlobals.call_indicator.connect(
		func setAnimation(anim_string, combatant):
			received_combatant = combatant
			indicator_animation = anim_string
			)
	CombatGlobals.manual_call_indicator.connect(manualCallIndicator)

#	if attached_combatant is ResEnemyCombatant:
#		pulse_gradient_sprite.self_modulate = Color.RED
#		turn_gradient_sprite.modulate = Color.RED
	select_target.attached_combatant = attached_combatant
	previous_value = attached_combatant.getMaxHealth()

func _process(_delta):
	updateBars()
	updateStatusEffects()
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
	health_bar.max_value = int(attached_combatant.BASE_STAT_VALUES['health'])
	health_bar.value = int(attached_combatant.STAT_VALUES['health'])
	absolute_health.text = str(health_bar.value)
	turn_charges.value = attached_combatant.TURN_CHARGES
	turn_charges.max_value = attached_combatant.MAX_TURN_CHARGES
	if attached_combatant.hasStatusEffect('Knock Out'):
		health_bar.hide()
	else:
		health_bar.show()

func updateStatusEffects():
	for effect in attached_combatant.STATUS_EFFECTS:
		if status_effects.get_children().has(effect.ICON) or permanent_status_effects.get_children().has(effect.ICON) or effect.ICON == null: continue
		var tick_down = preload("res://scenes/user_interface/StatusEffectTickDown.tscn").instantiate()
		tick_down.attached_status = effect
		var icon = effect.ICON
		icon.tooltip_text = effect.DESCRIPTION
		icon.add_child(tick_down)
		if effect.PERMANENT:
			permanent_status_effects.add_child(icon)
		else:
			status_effects.add_child(icon)

func _on_health_bar_value_changed(value):
	animateFaderBar(previous_value, attached_combatant.STAT_VALUES['health'])
	if first_turn: 
		indicator.hide()
	else:
		indicator.show()
	
	indicator_label.text = str(abs(previous_value - value))
	if attached_combatant.isDead():
		indicator_animator.play('KO')
		await indicator_animator.animation_finished
		return
	
	if indicator_animation == "Crit": indicator_label.text += " CRITICAL!"
	indicator_animator.play(indicator_animation)
	first_turn = false
	await indicator_animator.animation_finished
	previous_value = value
	indicator_animation = "Show"
	

func animateFaderBar(prev_val, value):
	if prev_val == value:
		return
	
	health_bar_fader.max_value = attached_combatant.getMaxHealth()
	health_bar_fader.value = prev_val
	print(prev_val, 'vs', value)
	if prev_val > value:
		health_bar_fader.modulate = Color.RED
	elif prev_val < value:
		health_bar_fader.modulate = Color.GREEN
	#health_bar_fader_animator.play("FadeIn")
	#await health_bar_fader_animator.animation_finished
	await get_tree().create_timer(0.25).timeout
	var tween = create_tween().set_parallel(true)
	tween.tween_method(setFaderBarValue, prev_val, value, 0.3)
	tween.tween_property(health_bar_fader, 'modulate', Color.BLACK, 0.4)
	#await tween.finished
	#health_bar_fader.hide()
	#if prev_val > value:
	#	tween.tween_property(health_bar_fader, 'modulate', Color.RED, 0.0)
	#elif prev_val < value:
	#	tween.tween_property(health_bar_fader, 'modulate', Color.GREEN, 0.0)
	#tween.tween_property(health_bar_fader, 'modulate', Color.TRANSPARENT, 0.6)
	#tween.set_parallel(true)

func setFaderBarValue(value):
	health_bar_fader.value = value


func manualCallIndicator(combatant: ResCombatant, text: String, animation: String):
	if attached_combatant == combatant:
		var secondary_indicator = preload("res://scenes/user_interface/SecondaryIndicator.tscn").instantiate()
		var y_placement = 0
		for child in secondary_prompts.get_children():
			y_placement -= 16
		secondary_prompts.add_child(secondary_indicator)
		secondary_indicator.playAnimation(indicator.global_position + Vector2(0, y_placement), text, animation)
