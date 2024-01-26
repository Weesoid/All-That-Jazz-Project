extends Node2D
class_name CombatBar

@onready var energy_bar = $EnergyBar
@onready var health_bar = $HealthBar
@onready var absolute_health = $AbsoluteHealth
@onready var absolute_energy = $AbsoluteEnergy
@onready var armor_icon = $ArmorIcon
@onready var status_effects = $StatusEffectContainer
@onready var indicator = $Indicator
@onready var indicator_label = $Indicator/Label
@onready var indicator_animator = $Indicator/AnimationPlayer
@onready var secondary_prompts = $Marker2D

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
	if attached_combatant is ResEnemyCombatant:
		energy_bar.hide()
		absolute_energy.hide()
	
	previous_value = attached_combatant.getMaxHealth()

func _process(_delta):
	updateBars()
	updateArmorIcon()
	updateStatusEffects()

func updateBars():
	health_bar.max_value = int(attached_combatant.BASE_STAT_VALUES['health'])
	health_bar.value = int(attached_combatant.STAT_VALUES['health'])
	energy_bar.max_value = int(attached_combatant.BASE_STAT_VALUES['verve'])
	energy_bar.value = int(attached_combatant.STAT_VALUES['verve'])
	absolute_health.text = str(health_bar.value)
	absolute_energy.text = str(energy_bar.value)
	if attached_combatant.isDead():
		hide()
	else:
		show()

func updateArmorIcon():
	if attached_combatant.isEquipped('armor'):
		var armor: ResArmor = attached_combatant.EQUIPMENT['armor']
		armor_icon.texture = armor.ICON
	else:
		armor_icon.texture = preload("res://images/icons/armor_none.png")

func updateStatusEffects():
	#print_orphan_nodes()
	for effect in attached_combatant.STATUS_EFFECTS:
		if status_effects.get_children().has(effect.ICON): continue
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
		self_modulate.a = 0.5
		return
	else:
		self_modulate.a = 1.0
	
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
			y_placement -= 24
		secondary_prompts.add_child(secondary_indicator)
		secondary_indicator.playAnimation(indicator.global_position + Vector2(0, y_placement), text, animation)
