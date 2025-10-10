extends ResStackItem
class_name ResCampItem

## Only uses ResHeal, ResCustomDamae, and ResApplyStatus
@export var effects: Array[ResAbilityEffect]
@export var party_wide: bool

func applyEffects(combatant: ResPlayerCombatant):
	if party_wide:
		for member in OverworldGlobals.getCombatantSquad('Player'):
			apply(member)
	else:
		apply(combatant)

func apply(combatant: ResPlayerCombatant):
	for effect in effects:
		if effect is ResHealEffect:
			CombatGlobals.calculateHealing(combatant, effect.heal, effect.use_multiplier)
			#CombatGlobals.manual_call_indicator
		elif effect is ResCustomDamageEffect:
			OverworldGlobals.damageMember(combatant, effect.damage, effect.use_damage_formula)
		elif effect is ResApplyStatusEffect:
			OverworldGlobals.addLingerEffect(combatant, effect.status_effect)

func getInformation():
	var out = '[center]'+OverworldGlobals.insertTextureCode(icon)+' '+name.to_upper()+'\n'
	out += CombatGlobals.getBasicEffectsDescription(effects,false)
	if party_wide:
		out = out.replace('Target', 'Party')
	if description != '':
		out += '\n'+description
	return out
