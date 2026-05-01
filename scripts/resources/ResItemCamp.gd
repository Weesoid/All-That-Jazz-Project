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

func apply(combatant: ResPlayerCombatant):
	if !canApply(combatant):
		return
	var key = name
	var count_appended:bool=false
	for effect in effects:
		var conditions_passed = CombatGlobals.checkConditions(effect.condition, combatant)
		if effect is ResHealEffect and conditions_passed:
			CombatGlobals.calculateHealing(combatant, effect.heal, effect.use_multiplier)
		elif effect is ResCustomDamageEffect and conditions_passed:
			OverworldGlobals.damageMember(combatant, effect.damage, effect.use_damage_formula)
		elif effect is ResApplyStatusEffect and conditions_passed:
			combatant.stored_status_effects.append(effect.status_effect.getFilename())
		elif effect is ResStatModifierEffect and conditions_passed:
			var dupe_count = getDupeCount(combatant)
			if dupe_count > 0 and !count_appended: 
				key += '^'+str(dupe_count)
				count_appended=true
			combatant.addTemporaryModifer(
				key, 
				effect.duration,
				effect.getModifications(),
				effect.stacks,
				effect.duration_type == ResStatModifierEffect.DurationType.BATTLE
				)
	
	combatant.addStrain(key, strain)

func getDupeCount(combatant:ResCombatant):
	var count = 0
	#var tracked_keys = []
	for key in combatant.item_strain_tracker.keys():
		var key_data = key.split('^')
		if key_data[0] == name:
			count += 1
		if key_data.size()>1: #and !tracked_keys.has(key):
			count = int(key_data[1])+1
			#tracked_keys.append(key)
	
	return count
	

#func combineStatModifiers(combatant:ResCombatant)-> Dictionary:
#	var all_modifiers=effects.filter(func(effect): return effect is ResStatModifierEffect)
#	var combined_modifiers = {}
#	for effect in all_modifiers:
#		var conditions_passed = CombatGlobals.checkConditions(effect.condition, combatant)
#		if conditions_passed:
#			CombatGlobals.appendStatModifications(combined_modifiers, effect.getModifiers())
#
#	return combined_modifiers

func getInformation():
	var out = '[center]'+OverworldGlobals.insertTextureCode(icon)+' '+name.to_upper()+'\n'
	out += strainCostLabel()+'\n'
	out += CombatGlobals.getBasicEffectsDescription(effects)
	if party_wide:
		out = out.replace('Target', 'Party')
	#out += SettingsGlobals.bb_line+'Strain '+strainCostLabel()
	if description != '':
		out += '\n[color=dim_gray]'+description
	return out

func strainCostLabel():
	var out = '[color=transparent]A[/color]'
	for i in range(strain):
		out += '[img]res://images/sprites/outlined_circle_filled.png[/img]'
	out += '[color=transparent]A[/color]'
	return out
