extends ResStackItem
class_name ResCampItem

## Only uses ResHeal, ResCustomDamage, ResStatModifierEffect, and ResApplyStatus
@export var effects: Array[ResAbilityEffect]
@export var strain: int = 1
@export var party_wide: bool

func canApply(combatant: ResPlayerCombatant):
	return (combatant.stat_values['strain']+strain) <= 4

func applyEffects(combatant: ResPlayerCombatant):
	if party_wide:
		for member in OverworldGlobals.getCombatantSquad('Player'):
			apply(member)
	else:
		apply(combatant)

# NOTE: Can only have ONE stat modifier effect.
func apply(combatant: ResPlayerCombatant):
	if !canApply(combatant):
		return
	var key = name
	for effect in effects:
		if effect is ResHealEffect:
			CombatGlobals.calculateHealing(combatant, effect.heal, effect.use_multiplier)
		elif effect is ResCustomDamageEffect:
			OverworldGlobals.damageMember(combatant, effect.damage, effect.use_damage_formula)
		elif effect is ResApplyStatusEffect:
			combatant.stored_status_effects.append(effect.status_effect.getFilename())
		elif effect is ResStatModifierEffect:
			combatant.addTemporaryModifer(
				name, 
				effect.duration,
				effect.getModifications(),
				effect.stacks,
				effect.duration_type == ResStatModifierEffect.DurationType.BATTLE
				)
			#print(combatant.temp_modifier_tracker)
			key = combatant.temp_modifier_tracker.keys().filter(func(key): return key.contains('|'+name))[0]
	
	combatant.addStrain(key, strain)

func getInformation():
	var out = '[center]'+OverworldGlobals.insertTextureCode(icon)+' '+name.to_upper()+'\n'
	out += CombatGlobals.getBasicEffectsDescription(effects)
	if party_wide:
		out = out.replace('Target', 'Party')
	if description != '':
		out += '\n'+description
	out += '\n'+SettingsGlobals.bb_line+strainCostLabel()
	return out

func strainCostLabel():
	var out = 'Strain '
	for i in range(strain):
		out += '[img]res://images/sprites/outlined_circle_filled.png[/img]'
	return out
