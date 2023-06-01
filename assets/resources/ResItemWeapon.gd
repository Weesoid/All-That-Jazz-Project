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

func equip(combatant: ResCombatant):
	combatant.EQUIPMENT['weapon'] = self

func animateCast(caster: ResCombatant):
	EFFECT.animateCast(caster)

func applyEffect(caster: ResCombatant, target: ResCombatant, animation_scene):
	EFFECT.applyEffects(caster, target, animation_scene)

func getStatModifications():
	return STAT_MODIFICATIONS
