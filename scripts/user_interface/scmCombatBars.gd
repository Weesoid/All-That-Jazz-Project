extends Node2D

# GAME PLAN, attach this to every combatant in CombatScene and set "attached
# _combatant" to it's respective combatant

@onready var energy_bar = $EnergyBar
@onready var health_bar = $HealthBar
@onready var armor_icon = $ArmorIcon
@onready var status_effects = $StatusEffectContainer
@onready var indicator = $Indicator
@onready var indicator_label = $Indicator/Label
@onready var indicator_animator = $Indicator/AnimationPlayer


var indicator_animation = "Show"
var received_combatant: ResCombatant
var attached_combatant: ResCombatant
var previous_value = 0
var current_bar_value = 100

func _ready():
	CombatGlobals.call_indicator.connect(
		func setAnimation(anim_string, combatant):
			received_combatant = combatant
			indicator_animation = anim_string
			)
	CombatGlobals.manual_call_indicator.connect(manualCallIndicator)
	if attached_combatant is ResEnemyCombatant:
		energy_bar.hide()
	

func _process(_delta):
	updateBars()
	updateArmorIcon()
	updateStatusEffects()

func updateBars():
	health_bar.max_value = attached_combatant.BASE_STAT_VALUES['health']
	health_bar.value = attached_combatant.STAT_VALUES['health']
	energy_bar.max_value = attached_combatant.BASE_STAT_VALUES['verve']
	energy_bar.value = attached_combatant.STAT_VALUES['verve']

func updateArmorIcon():
	var armor: ResArmor = attached_combatant.EQUIPMENT['armor']
	if armor == null:
		armor_icon.texture = preload("res://assets/icons/armor_none.png")
	elif armor.ARMOR_TYPE == CombatGlobals.loadArmorType('Light'):
		armor_icon.texture = preload("res://assets/icons/armor_half.png")
	elif armor.ARMOR_TYPE == CombatGlobals.loadArmorType('Heavy'):
		armor_icon.texture = preload("res://assets/icons/armor_full.png")

func updateStatusEffects():
	for effect in attached_combatant.STATUS_EFFECTS:
		if status_effects.get_children().has(effect.ICON): continue
		status_effects.add_child(effect.ICON)

func _on_health_bar_value_changed(value):
	if value == health_bar.max_value:
		previous_value = health_bar.max_value
		return
	if attached_combatant.isDead():
		indicator_animator.play('KO')
		await indicator_animator.animation_finished
		hide()
		return
	
	if received_combatant == attached_combatant:
		indicator_label.text = str(previous_value - value)
		match indicator_animation:
			"Crit": indicator_label.text += " CRITICAL!"
		indicator_animator.play(indicator_animation)
		await indicator_animator.animation_finished
		previous_value = value
		indicator_animation = "Show"

func manualCallIndicator(combatant: ResCombatant, text: String, animation: String):
	if attached_combatant == combatant:
		var secondary_indicator = preload("res://scenes/user_interface/SecondaryIndicator.tscn").instantiate()
		add_child(secondary_indicator)
		secondary_indicator.playAnimation(indicator.global_position, text, animation)
