extends ResItem
class_name ResWeapon

enum DamageType {
	NEUTRAL, # 1
	EDGED, # 2
	BLUNT # 3
}

@export var DAMAGE_TYPE: DamageType
@export var STAT_MODIFICATIONS = {}
@export var EFFECT: ResAbility
var EQUIPPED_COMBATANT: ResCombatant

func equip(combatant: ResCombatant):
	if EQUIPPED_COMBATANT != null: 
		unequip()
	EQUIPPED_COMBATANT = combatant
	combatant.EQUIPMENT['weapon'] = self
	applyStatModifications()

func unequip():
	removeStatModifications()
	EQUIPPED_COMBATANT.EQUIPMENT['weapon'] = null
	EQUIPPED_COMBATANT = null

func applyStatModifications():
	if STAT_MODIFICATIONS.is_empty(): return
	for key in EQUIPPED_COMBATANT.BASE_STAT_VALUES.keys():
		if STAT_MODIFICATIONS.has(key):
			EQUIPPED_COMBATANT.BASE_STAT_VALUES[key] += STAT_MODIFICATIONS[key]
			EQUIPPED_COMBATANT.STAT_VALUES[key] = EQUIPPED_COMBATANT.BASE_STAT_VALUES[key]

func removeStatModifications():
	if STAT_MODIFICATIONS.is_empty(): return
	for key in EQUIPPED_COMBATANT.BASE_STAT_VALUES.keys():
		if STAT_MODIFICATIONS.has(key):
			EQUIPPED_COMBATANT.BASE_STAT_VALUES[key] -= STAT_MODIFICATIONS[key]
			EQUIPPED_COMBATANT.STAT_VALUES[key] = EQUIPPED_COMBATANT.BASE_STAT_VALUES[key]

func getStringStats():
	var result = ""
	for key in STAT_MODIFICATIONS.keys():
		result += key.to_upper() + ": " + str(STAT_MODIFICATIONS[key]) + "\n"
	return result


func animateCast(caster: ResCombatant):
	EFFECT.animateCast(caster)

func applyEffect(caster: ResCombatant, target: ResCombatant, animation_scene):
	EFFECT.applyEffects(caster, target, animation_scene)

func getStatModifications():
	return STAT_MODIFICATIONS
