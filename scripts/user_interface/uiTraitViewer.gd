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
			trait_container.add_child(UIGlobals.createStatModifierLabel(modifier, selected_combatant,true))
		elif type == ModifierTypes.TEMPORARY:
			temporary_container.add_child(UIGlobals.createStatModifierLabel(modifier, selected_combatant,true))
		elif type == ModifierTypes.INJURY:
			injury_container.add_child(UIGlobals.createStatModifierLabel(modifier, selected_combatant,true))
	await get_tree().process_frame
	trait_container.visible = trait_container.get_child_count() > 1
	temporary_container.visible = temporary_container.get_child_count() > 1
	injury_container.visible = injury_container.get_child_count() > 1


func getModifierType(modifier)-> ModifierTypes:
	if selected_combatant.getTraitsWithFlag('injury').has(modifier):
		return ModifierTypes.INJURY
	elif selected_combatant.stat_modifiers.has(modifier) and modifier.contains('tempmod/'):
		return ModifierTypes.TEMPORARY
	else:
		return ModifierTypes.TRAIT
