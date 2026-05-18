extends ResStackItem
class_name ResCampItem

## Only uses ResHeal, ResCustomDamage, ResStatModifierEffect, and ResApplyStatus
@export var effects: Array[ResAbilityEffect]
@export var strain: int = 1
@export var party_wide: bool

func canApply(combatant: ResPlayerCombatant):
	return (combatant.stat_values['strain']+strain) <= PlayerGlobals.strain_cap# and !combatant.isDead(true)

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
	var modifiers_added:bool=false
	var strain_added:bool=false
	var modifier_data = combineStatModifiers(combatant)
	
	for effect in effects:
		var conditions_passed = CombatGlobals.checkConditions(effect.condition, combatant)
		if effect is ResHealEffect and conditions_passed:
			CombatGlobals.calculateHealing(combatant, effect.heal, effect.use_multiplier)
		elif effect is ResCustomDamageEffect and conditions_passed:
			OverworldGlobals.damageMember(combatant, effect.damage, effect.use_damage_formula)
		elif effect is ResApplyStatusEffect and conditions_passed:
			combatant.stored_status_effects.append(effect.status_effect.getFilename())
		elif effect is ResStatModifierEffect and !modifiers_added:
			var dupe_count = getDupeCount(combatant)
			if dupe_count > 0 and !count_appended: 
				key += '^'+str(dupe_count)
				count_appended=true
			combatant.addTemporaryModifer(
				key, 
				modifier_data[1].duration,
				modifier_data[0],
				effect.stacks,
				modifier_data[1].duration_type == ResStatModifierEffect.DurationType.BATTLE
				)
			modifiers_added = true
			strain_added = true
	
	if !strain_added and strain > 0:
		var count = getDupeCount(combatant)
		if count > 0:
			key += '^'+str(count)
		combatant.addTemporaryModifer(
			key, 
			1,
			{'strain': strain},
			false,
			ResStatModifierEffect.DurationType.BATTLE
			)
		strain_added = true
	
	#combatant.addStrain(key, strain)

func getDupeCount(combatant:ResCombatant):
	var count = 0
	#var tracked_keys = []
	for key in combatant.stat_modifiers.keys():
		var key_data = key.split('|')
		if key_data.size() <= 1:
			continue
		if key_data[1] == name:
			count += 1
		elif key_data[1].contains('^') and key_data[1].split('^').size()>1:
			count = int(key_data[1])+1
	
	return count

#func getDupeCountNonEffect(combatant:ResCombatant):
#	var count = 0
#
#	for key in combatant.stat_modifiers.keys():
#		var key_data = key.split('|')
#		if key_data.size() <= 1:
#			continue
#		if key_data[1] == name:
#			print('countin!')
#			count += 1
#		elif key_data[1].contains('^') and key_data[1].split('^').size()>1:
#			count = int(key_data[1])+1
#
#	return count

# Returns [<Combined modifier effects, longest duration modifier]
func combineStatModifiers(combatant:ResCombatant)-> Array:
	randomize()
	var all_modifiers=effects.filter(func(effect): return effect is ResStatModifierEffect and CombatGlobals.checkConditions(effect.condition, combatant))
	var longest_duration_modifier = getLongestModiferDuration(all_modifiers)
	var combined_modifiers = {}
	for effect in all_modifiers:
		combined_modifiers = CombatGlobals.combineDictionaries(combined_modifiers, effect.getModifications())
	if strain > 0:
		combined_modifiers = CombatGlobals.combineDictionaries(combined_modifiers, {'strain':strain})
	return [combined_modifiers,longest_duration_modifier]

func getLongestModiferDuration(modifier_effects:Array):
	if modifier_effects.is_empty():
		return []
	
	var longest_modifier: ResStatModifierEffect = modifier_effects[0]
	
	for current_modifier in modifier_effects:
		if longest_modifier.duration_type > current_modifier.duration_type:
			continue
		elif longest_modifier.duration_type < current_modifier.duration_type:
			longest_modifier = current_modifier
		else:
			longest_modifier = current_modifier if current_modifier.duration > longest_modifier.duration else longest_modifier
	
	return longest_modifier

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
