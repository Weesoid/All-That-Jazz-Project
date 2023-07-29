extends Node2D

# GAME PLAN, attach this to every combatant in CombatScene and set "attached
# _combatant" to it's respective combatant

@onready var energy_bar = $EnergyBar
@onready var health_bar = $HealthBar
@onready var armor_icon = $ArmorIcon
@onready var status_effects = $StatusEffectContainer

var attached_combatant: ResCombatant

func _ready():
	if attached_combatant is ResEnemyCombatant:
		energy_bar.hide()

func _process(_delta):
	if attached_combatant.isDead():
		queue_free()
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
	elif armor.ARMOR_TYPE == armor.ArmorType.LIGHT:
		armor_icon.texture = preload("res://assets/icons/armor_half.png")
	elif armor.ARMOR_TYPE == armor.ArmorType.HEAVY:
		armor_icon.texture = preload("res://assets/icons/armor_full.png")

func updateStatusEffects():
	for effect in attached_combatant.STATUS_EFFECTS:
		if status_effects.get_children().has(effect.ICON): continue
		status_effects.add_child(effect.ICON)
