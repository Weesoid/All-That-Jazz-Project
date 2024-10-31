extends Node2D
class_name CombatBar

@onready var health_bar = $HealthBar
@onready var absolute_health = $HealthBar/AbsoluteHealth
@onready var status_effects = $HealthBar/StatusEffectContainer
@onready var indicator = $Indicator
@onready var indicator_label = $Indicator/Label
@onready var indicator_animator = $Indicator/AnimationPlayer
@onready var secondary_prompts = $Marker2D
@onready var turn_gradient = $HealthBar/TurnGradient/AnimationPlayer
@onready var select_target = $SelectTarget
@onready var turn_charges: CustomCountBar = $HealthBar/AbsoluteHealth/TurnCharges
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
		if status_effects.get_children().has(effect.ICON) or effect.ICON == null: continue
		var tick_down = preload("res://scenes/user_interface/StatusEffectTickDown.tscn").instantiate()
		tick_down.attached_status = effect
		var icon = effect.ICON
		icon.add_child(tick_down)
		status_effects.add_child(icon)

func _on_health_bar_value_changed(value):
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

func manualCallIndicator(combatant: ResCombatant, text: String, animation: String):
	if attached_combatant == combatant:
		var secondary_indicator = preload("res://scenes/user_interface/SecondaryIndicator.tscn").instantiate()
		var y_placement = 0
		for child in secondary_prompts.get_children():
			y_placement -= 16
		secondary_prompts.add_child(secondary_indicator)
		secondary_indicator.playAnimation(indicator.global_position + Vector2(0, y_placement), text, animation)
