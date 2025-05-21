extends ResEquippable
class_name ResWeapon

@export var EFFECT: ResAbility
@export var USE_REQUIREMENT: Dictionary = {
	'handling': 1
}
@export var max_durability = 100
var durability: int

func equip(combatant: ResCombatant):
	if isEquipped():
		unequip()
	
	EQUIPPED_COMBATANT = combatant
	EQUIPPED_COMBATANT.EQUIPPED_WEAPON = self
	
	if !STAT_MODIFICATIONS.is_empty():
		applyStatModifications()

func unequip():
	if !STAT_MODIFICATIONS.is_empty():
		removeStatModifications()
	
	EQUIPPED_COMBATANT = null

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
		OverworldGlobals.getPlayer().prompt.showPrompt('[color=yellow]%s[/color] fully repaired.' % NAME)

func canUse(combatant: ResCombatant):
	for stat in USE_REQUIREMENT.keys():
		if USE_REQUIREMENT[stat] > combatant.STAT_VALUES[stat]:
			return false
	
	return true

func getInformation():
	var handling_bb = '[img]res://images/sprites/circle_filled.png[/img]'
	var handling_requirement = ''
	var out = OverworldGlobals.insertTextureCode(ICON)+' '+NAME.to_upper()+'\n'
	for i in USE_REQUIREMENT['handling']:
		handling_requirement += handling_bb
	out += handling_requirement+'\n'
	out += DESCRIPTION + '\n\n'
	out += EFFECT.getRichDescription()
	return out

func getGeneralInfo():
	var out = ''
	if VALUE > 0:
		out += '[img]res://images/sprites/trade_slip.png[/img]%s	' % VALUE
	out += '[img]res://images/sprites/icon_durability.png[/img]%s/%s	' % [durability,max_durability]
	if USE_REQUIREMENT['handling'] > 0:
		out += '[img]res://images/sprites/circle_filled.png[/img] %s' % USE_REQUIREMENT['handling']
	return out
