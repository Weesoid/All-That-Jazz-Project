extends ResStackItem
class_name ResConsumable

@export var EFFECT: ResAbility

func use():
	STACK -= 1
	if STACK <= 0:
		PlayerGlobals.INVENTORY.erase(self)

func animateCast(caster: ResCombatant):
	EFFECT.animateCast(caster)

func applyEffect(caster: ResCombatant, target: ResCombatant, animation_scene):
	EFFECT.applyEffects(caster, target, animation_scene)
