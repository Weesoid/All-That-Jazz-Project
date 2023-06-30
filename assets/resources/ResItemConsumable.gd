extends ResItem
class_name ResConsumable

@export var EFFECT: ResAbility

var STACK = 1

func use():
	STACK -= 1
	if STACK <= 0:
		PlayerGlobals.INVENTORY.erase(self)
		PlayerGlobals.EQUIPPED_ARROW = null

func animateCast(caster: ResCombatant):
	EFFECT.animateCast(caster)

func applyEffect(caster: ResCombatant, target: ResCombatant, animation_scene):
	EFFECT.applyEffects(caster, target, animation_scene)

func _to_string():
	return str(NAME, ' x', STACK)
