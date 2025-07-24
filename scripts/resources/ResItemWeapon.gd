extends ResEquippable
class_name ResWeapon

@export var effect: ResAbility
@export var use_requirement: Dictionary = {
	'handling': 1
}
@export var max_durability = 100
var durability: int

func equip(combatant: ResCombatant):
	if isEquipped():
		unequip()
	
	equipped_combatant = combatant
	equipped_combatant.equipped_weapon = self
	
	if !stat_modifications.is_empty():
		applyStatModifications()

func unequip():
	if !stat_modifications.is_empty():
		removeStatModifications()
	
	equipped_combatant = null

func useDurability():
	durability -= 1
	if durability <= 0:
		durability = 0

func restoreDurability(amount: int):
	if (durability + amount) > max_durability:
		durability = max_durability
	else:
		durability += amount
	
	if durability == max_durability:
		OverworldGlobals.showPrompt('[color=yellow]%s[/color] fully repaired.' % NAME)

func canUse(combatant: ResCombatant):
	for stat in use_requirement.keys():
		if use_requirement[stat] > combatant.stat_values[stat]:
			return false
	
	return true

func getInformation():
	var handling_bb = '[img]res://images/sprites/circle_filled.png[/img]'
	var handling_requirement = ''
	var out = OverworldGlobals.insertTextureCode(icon)+' '+NAME.to_upper()+'\n'
	for i in use_requirement['handling']:
		handling_requirement += handling_bb
	out += handling_requirement+'\n'
	out += description + '\n\n'
	out += effect.getRichDescription()
	out += ' [color=yellow] Uses: %s/%s' % [durability,max_durability]
	return out

func getGeneralInfo():
	var out = ''
	if value > 0:
		out += '[img]res://images/sprites/trade_slip.png[/img]%s	' % value
	out += '[img]res://images/sprites/icon_durability.png[/img]%s/%s	' % [durability,max_durability]
	if use_requirement['handling'] > 0:
		out += '[img]res://images/sprites/circle_filled.png[/img] %s' % use_requirement['handling']
	return out
