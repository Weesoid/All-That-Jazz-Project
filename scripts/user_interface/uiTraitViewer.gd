extends VBoxContainer

enum TraitTypes {
	#LINGER,
	BUFF,
	UNIQUE,
	DEBUFF,
	SPECIAL
}

@onready var trait_container = $Temperment/TraitContainer
var selected_combatant: ResPlayerCombatant

func updateTraits(set_combatant: ResPlayerCombatant=null):
	if set_combatant != null:
		selected_combatant = set_combatant
	
	for child in trait_container.get_children():
		child.queue_free()
	
	selected_combatant.applyTraits()
	selected_combatant.traits.sort_custom(func(a,b): return getTraitType(a) < getTraitType(b))
	
	for p_trait in selected_combatant.traits:
		trait_container.add_child(createTraitLabel(p_trait))
	if selected_combatant.hasEquippedWeapon() and !selected_combatant.equipped_weapon.canUse(selected_combatant):
		selected_combatant.unequipWeapon()

func createTraitLabel(p_trait: String):
	var bb = '[table=2][cell]'+getBBTraitIcon(p_trait)+'[/cell]'
	var trait_name = getTraitName(p_trait).capitalize()
	var trait_label = RichTextLabel.new()
	trait_label.bbcode_enabled = true
	trait_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	trait_label.fit_content = true
	trait_label.text = bb+'[cell]'+trait_name+'[/cell][/table]'
	trait_label.tooltip_text = CombatGlobals.getStatListString(selected_combatant.stat_modifiers[getTraitName(p_trait)],false)
	return trait_label

func getBBTraitIcon(p_trait:String):
	if getTraitType(p_trait)==TraitTypes.BUFF:
		return '[img %s]res://images/status_icons/buff.png[/img]' % SettingsGlobals.ui_colors['up-bb'].replace('[','').replace(']','')
	elif getTraitType(p_trait)==TraitTypes.DEBUFF:
		return '[img %s]res://images/status_icons/debuff.png[/img]' % SettingsGlobals.ui_colors['down-bb'].replace('[','').replace(']','')
	elif getTraitType(p_trait)==TraitTypes.UNIQUE:
		return '[img %s]res://images/status_icons/quirk.png[/img]' % SettingsGlobals.ui_colors['special-bb'].replace('[','').replace(']','')

func getTraitType(p_trait)->TraitTypes:
	var positive_count = 0
	var negative_count = 0
	
	for i in selected_combatant.stat_modifiers[getTraitName(p_trait)]:
		var value = selected_combatant.stat_modifiers[getTraitName(p_trait)][i]
		if value > 0:
			positive_count += 1
		elif value < 0:
			negative_count += 1
	
	if negative_count == 0:
		return TraitTypes.BUFF
	elif positive_count == 0:
		return TraitTypes.DEBUFF
	elif positive_count > 0 and negative_count > 0:
		return TraitTypes.UNIQUE
	else:
		return TraitTypes.SPECIAL

func getTraitName(p_trait:String)->String:
	return p_trait.split('/')[0]
