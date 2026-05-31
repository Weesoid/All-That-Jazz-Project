extends RichTextLabel
class_name StatModifierLabel


# TODO CLEANUP
func setModifier(p_trait:String, combatant:ResCombatant, left_aligned:bool=false):
	var bb = '[table=2]'
	var trait_name = p_trait.split('/')[0].capitalize()
	bbcode_enabled = true
	autowrap_mode = TextServer.AUTOWRAP_OFF
	fit_content = true
	if p_trait.contains('|'):
		var duration_type = ''
		if p_trait.contains('battle/'):
			duration_type = 'Battles'
		elif p_trait.contains('turns/'):
			duration_type = 'Turns'
		text = bb+'[cell]'+p_trait.split('|')[1]+' (%s %s)' % [combatant.temp_modifier_tracker[p_trait], duration_type]+'[/cell]'
		UIGlobals.addTooltip(
			self, 
			CombatGlobals.getStatListString(combatant.stat_modifiers[p_trait]), 
			CustomTooltip.AnchorPreset.LEFT if !left_aligned else CustomTooltip.AnchorPreset.RIGHT,
			0.0,
			true
			)
	else:
		text = bb+'[cell]'+trait_name+'[/cell]'
		UIGlobals.addTooltip(
			self, 
			CombatGlobals.getStatListString(combatant.stat_modifiers[p_trait.split('/')[0]]), 
			CustomTooltip.AnchorPreset.LEFT if !left_aligned else CustomTooltip.AnchorPreset.RIGHT,
			0.0,
			true
			)
	text += ('[cell]'+getBBmodifierIcon(p_trait,combatant)+'[/cell][/table]')
	if left_aligned:
		text = text.replace('[right]','')
		size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

func getBBmodifierIcon(modifier:String, combatant:ResCombatant):
	var bb_icon:String
	var modifier_type:String #= getModifierType(modifier)
	var modifier_effects:String = getModifierEffects(modifier, combatant)
	if combatant is ResPlayerCombatant and combatant.getTraitsWithFlag('injury').has(modifier):
		modifier_type = 'injury'#return ModifierTypes.INJURY
	elif combatant.stat_modifiers.has(modifier) and modifier.contains('tempmod/'):
		modifier_type = 'temporary'#return ModifierTypes.TEMPORARY
	else:
		modifier_type = 'trait'#return ModifierTypes.TRAIT
	
	match modifier_effects:
		'buff': bb_icon = '[img %s]' % SettingsGlobals.ui_colors['up-bb-nobracket']
		'debuff': bb_icon = '[img %s]' % SettingsGlobals.ui_colors['down-bb-nobracket']
		'special': bb_icon = '[img %s]' % SettingsGlobals.ui_colors['special-bb-nobracket']
	
	match modifier_type:
		'trait':
			if modifier_effects == 'buff':
				bb_icon+="res://images/status_icons/buff.png"
			elif modifier_effects == 'debuff':
				bb_icon+="res://images/status_icons/debuff.png"
			elif modifier_effects == 'special':
				bb_icon+="res://images/status_icons/quirk.png"
		'temporary': bb_icon+="res://images/status_icons/hourglass.png"
		'injury': bb_icon+="res://images/status_icons/injury.png"
	bb_icon += '[/img]'
	
	return bb_icon

func getModifierEffects(p_trait, combatant):
	var positive_count = 0
	var negative_count = 0
	var modifier_id 
	if p_trait.contains('|'):
		modifier_id = p_trait
	else:
		modifier_id = p_trait.split('/')[0]
	
	for i in combatant.stat_modifiers[modifier_id]:
		var value = combatant.stat_modifiers[modifier_id][i]
		if value > 0:
			positive_count += 1
		elif value < 0:
			negative_count += 1
	
	if negative_count == 0:
		return 'buff'
	elif positive_count == 0:
		return 'debuff'
	else:
		return 'special'
