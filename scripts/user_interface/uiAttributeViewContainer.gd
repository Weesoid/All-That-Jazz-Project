extends Control

@onready var combatant: ResCombatant

func setCombatant(combatant):
	if combatant == null:
		return
	
	for stat_tracker in get_children():
		stat_tracker.combatant = combatant

func _process(_delta):
	setCombatant(combatant)
#	if combatant != null:
#		hp_text.text = '%s/%s' % [combatant.stat_values['health'], combatant.base_stat_values['health']]
#		hp_val.value = combatant.stat_values['health']
#		hp_val.max_value = combatant.base_stat_values['health']
#		brawn_val.text = str('%s - %s' % [calcDamage('min'),calcDamage('max')])
##		grit_val.value = combatant.stat_values['defense'] * 100
#		handling_val.max_value = 4
#		handling_val.value = combatant.stat_values['handling']
#		if combatant.stat_values['speed'] >= -99:
#			hustle_val.text = str(combatant.stat_values['speed'])
#		else:
#			hustle_val.text = 'IMMOBILIZED'
#		#acc_val.value = combatant.stat_values['accuracy'] * 100
#		crit_d_val.text = str(round((combatant.stat_values['crit_dmg']*100)-100))+'%'
#		crit_val.value = combatant.stat_values['crit'] * 100
#		resist_val.value = combatant.stat_values['resist'] * 100
#		if combatant.stat_values['heal_mult'] > 0:
#			healm_val.text = str(round((combatant.stat_values['heal_mult']*100)-100))+'%'
#		else:
#			healm_val.text = 'BROKEN'
#		if combatant.stat_values.has('resolve'):
#			resolve_val.value = combatant.stat_values['resolve']
#			resolve_val.max_value = combatant.getMaxResolve()
#		if combatant.stat_values.has('strain'):
#			strain_val.value = combatant.stat_values['strain']
#			strain_val.max_value = 4
#
#		highlightModifiedStats(brawn_val, 'damage')
##		highlightModifiedStats(grit_val, 'defense')
#		highlightModifiedStats(handling_val, 'handling')
#		highlightModifiedStats(hustle_val, 'speed')
#		#highlightModifiedStats(acc_val, 'accuracy')
#		highlightModifiedStats(crit_d_val, 'crit_dmg')
#		highlightModifiedStats(crit_val, 'crit')
#		highlightModifiedStats(resist_val, 'resist')
#		highlightModifiedStats(healm_val, 'heal_mult')
#		if combatant.stat_values.has('resolve'):
#			highlightModifiedStats(resolve_val, 'resolve')
#
#func calcDamage(val:String):
#	var damage = combatant.stat_values['damage']*combatant.stat_values.get('dmg_modifier',1.0)
#	var variance = (damage*combatant.stat_values['dmg_variance'])
#
#	match val:
#		'min': return round(damage-variance)
#		'max': return round(damage+variance)
#
#func highlightModifiedStats(value_node, stat):
##	if stat == 'crit':
##		print(combatant.stat_values[stat], ' | ', combatant.base_stat_values[stat])
#	if combatant.stat_values[stat] == combatant.base_stat_values[stat]:
#		value_node.modulate = Color.WHITE
#	elif combatant.stat_values[stat] > combatant.base_stat_values[stat]:
#		value_node.modulate = SettingsGlobals.ui_colors['up']
#	elif combatant.stat_values[stat] < combatant.base_stat_values[stat]:
#		value_node.modulate = SettingsGlobals.ui_colors['down']
#
#func getAbilities(view_combatant:ResCombatant):
#	var ability_set = '[table=2]'
#
#	for ability in view_combatant.ability_set:
#		ability_set += '[cell][hint='+ability.description+']'+ability.name + '[/hint][/cell][cell]' + ability.getPositionIcon(true, combatant is ResEnemyCombatant)+'[/cell]\n'
#
#	ability_set += '[/table]'
#	return ability_set
#
#func formatModifiers(stat_dict: Dictionary) -> String:
#	var result = ""
#	for key in stat_dict.keys():
#		var value = stat_dict[key]
#		if value is float: 
#			value *= 100.0
#		if stat_dict[key] > 0 and stat_dict[key]:
#			if value is float: 
#				result += "+" + str(value) + "% " +key.to_upper().replace('_', ' ') + "\n"
#			else:
#				result += "+" + str(value) + " " +key.to_upper().replace('_', ' ') +  "\n"
#		else:
#			if value is float: 
#				result += str(value) + "% " +key.to_upper().replace('_', ' ') +  "\n"
#			else:
#				result += str(value) + " " +key.to_upper().replacee('_', ' ') + "\n"
#	return result
