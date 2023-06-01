extends ResItem
class_name ResConsumable

@export var EFFECT: ResAbility

var STACK = 1

func USE():
	STACK -= 1
	if STACK <= 0:
		PlayerGlobals.INVENTORY.erase(NAME)

func animateCast(caster: ResCombatant):
	EFFECT.animateCast(caster)

func applyEffect(caster: ResCombatant, target: ResCombatant, animation_scene):
	EFFECT.applyEffects(caster, target, animation_scene)
