extends VBoxContainer
class_name ModifierViewer

enum ModifierTypes {
	TRAIT,
	TEMPORARY,
	INJURY
}
enum ModifierEffects {
	BUFF,
	DEBUFF,
	SPECIAL
}

@onready var trait_container = $ScrollContainer/VBoxContainer/Traits
@onready var temporary_container = $ScrollContainer/VBoxContainer/Temporaries
@onready var injury_container = $ScrollContainer/VBoxContainer/Injuries
var selected_combatant: ResPlayerCombatant

func _ready():
	pass
#	trait_container.get_parent().show()
#	temporary_container.get_parent().hide()
#	injury_container.get_parent().hide()

func loadModifiers(set_combatant: ResPlayerCombatant=null):
	if set_combatant != null:
		selected_combatant = set_combatant
	
	for child in trait_container.get_children():
		if child.name == 'Title': continue
		child.queue_free()
	for child in temporary_container.get_children():
		if child.name == 'Title': continue
		child.queue_free()
	for child in injury_container.get_children():
		if child.name == 'Title': continue
		child.queue_free()
	
	
	var all_modifiers = selected_combatant.traits.duplicate()
	all_modifiers.append_array(selected_combatant.getTemporaryModifierKeys('/'))
	for modifier in all_modifiers:
		var type = getModifierType(modifier)
		if type == ModifierTypes.TRAIT:
			trait_container.add_child(createModifierLabel(modifier))
		elif type == ModifierTypes.TEMPORARY:
			temporary_container.add_child(createModifierLabel(modifier))
		elif type == ModifierTypes.INJURY:
			injury_container.add_child(createModifierLabel(modifier))
	await get_tree().process_frame
#	traits_button.setDisabled(trait_container.get_children().is_empty())
#	temporaries_button.setDisabled(temporary_container.get_children().is_empty())
#	injuries_button.setDisabled(injury_container.get_children().is_empty())
	trait_container.visible = trait_container.get_child_count() > 1
	temporary_container.visible = temporary_container.get_child_count() > 1
	injury_container.visible = injury_container.get_child_count() > 1
	
#	if selected_combatant.hasEquippedWeapon() and !selected_combatant.equipped_weapon.canUse(selected_combatant):
#		selected_combatant.unequipWeapon()

func createModifierLabel(p_trait: String):
	var bb = '[table=2][cell]'+getBBmodifierIcon(p_trait)+'[/cell]'
	var trait_name = getTraitName(p_trait).capitalize()
	var trait_label = RichTextLabel.new()
	trait_label.bbcode_enabled = true
	trait_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	trait_label.fit_content = true
	if p_trait.contains('|'):
		var duration_type = ''
		if p_trait.contains('battle/'):
			duration_type = 'Battles'
		elif p_trait.contains('turns/'):
			duration_type = 'Turns'
		trait_label.text = bb+'[cell]'+p_trait.split('|')[1]+' (%s %s)' % [selected_combatant.temp_modifier_tracker[p_trait], duration_type]+'[/cell][/table]'
		UIGlobals.addTooltip(
			trait_label, 
			CombatGlobals.getStatListString(selected_combatant.stat_modifiers[p_trait]), 
			CustomTooltip.AnchorPreset.RIGHT
			)
		#trait_label.tooltip_text = CombatGlobals.getStatListString(selected_combatant.stat_modifiers[p_trait],false)
	else:
		trait_label.text = bb+'[cell]'+trait_name+'[/cell][/table]'
		UIGlobals.addTooltip(
			trait_label, 
			CombatGlobals.getStatListString(selected_combatant.stat_modifiers[getTraitName(p_trait)]), 
			CustomTooltip.AnchorPreset.RIGHT
			)
		#trait_label.tooltip_text = CombatGlobals.getStatListString(selected_combatant.stat_modifiers[getTraitName(p_trait)],false)
	return trait_label

# TODO modifier class (icon), modifier efffects (color) 
func getBBmodifierIcon(modifier:String):
	var bb_icon:String
	var modifier_type = getModifierType(modifier)
	var modifier_effects = getModifierEffects(modifier)
	match modifier_effects:
		ModifierEffects.BUFF: bb_icon = '[img %s]' % SettingsGlobals.ui_colors['up-bb-nobracket']
		ModifierEffects.DEBUFF: bb_icon = '[img %s]' % SettingsGlobals.ui_colors['down-bb-nobracket']
		ModifierEffects.SPECIAL: bb_icon = '[img %s]' % SettingsGlobals.ui_colors['special-bb-nobracket']
	
	match modifier_type:
		ModifierTypes.TRAIT:
			if modifier_effects == ModifierEffects.BUFF:
				bb_icon+="res://images/status_icons/buff.png"
			elif modifier_effects == ModifierEffects.DEBUFF:
				bb_icon+="res://images/status_icons/debuff.png"
			elif modifier_effects == ModifierEffects.SPECIAL:
				bb_icon+="res://images/status_icons/quirk.png"
		ModifierTypes.TEMPORARY: bb_icon+="res://images/status_icons/hourglass.png"
		ModifierTypes.INJURY: bb_icon+="res://images/status_icons/injury.png"
	bb_icon += '[/img]'
	
	return bb_icon

func getModifierType(modifier)-> ModifierTypes:
	if selected_combatant.getTraitsWithFlag('injury').has(modifier):
		return ModifierTypes.INJURY
	elif selected_combatant.stat_modifiers.has(modifier) and modifier.contains('tempmod/'):
		return ModifierTypes.TEMPORARY
	else:
		return ModifierTypes.TRAIT

func getModifierEffects(p_trait)->ModifierEffects:
	var positive_count = 0
	var negative_count = 0
	var modifier_id 
	if p_trait.contains('|'):
		modifier_id = p_trait
	else:
		modifier_id = getTraitName(p_trait)
	
	for i in selected_combatant.stat_modifiers[modifier_id]:
		var value = selected_combatant.stat_modifiers[modifier_id][i]
		if value > 0:
			positive_count += 1
		elif value < 0:
			negative_count += 1
	
	if negative_count == 0:
		return ModifierEffects.BUFF
	elif positive_count == 0:
		return ModifierEffects.DEBUFF
	else:
		return ModifierEffects.SPECIAL

func getTraitName(p_trait:String)->String:
	return p_trait.split('/')[0]
