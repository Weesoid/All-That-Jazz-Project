extends ResEquippable
class_name ResWeapon

@export var effect: ResAbility
@export var handling_requirement = 1
@export var max_durability = 100
@export var repair_item: ResItem
## Repair cost per durability
@export var repair_cost = 1 
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
	equipped_combatant.file_references['equipped_weapon'][1] = durability

func repair(repair_amount: int):
	if !canRepair(repair_amount):
		return
	
	if (durability + repair_amount) > max_durability:
		durability = max_durability
	else:
		durability += repair_amount
	
	InventoryGlobals.removeItemResource(repair_item,repair_cost*repair_amount)
	InventoryGlobals.item_repaired.emit(self, durability)
#	if durability == max_durability:
#		OverworldGlobals.showPrompt('[color=yellow]%s[/color] fully repaired.' % name)

func canRepair(repair_amount:int):
	return InventoryGlobals.hasItem(repair_item, repair_cost*repair_amount) and durability != max_durability

func canUse(combatant: ResCombatant):
	return combatant.stat_values['handling'] >= handling_requirement

func getInformation():
	var handling_bb = '[img]res://images/sprites/circle_filled_small.png[/img]'
	var handling_requirement_text = '[center]'
	var out = '[center]'+OverworldGlobals.insertTextureCode(icon)+' '+name.to_upper()+'\n'
	for i in range(handling_requirement):
		handling_requirement_text += handling_bb+' '
	#handling_requirement_text += '[/center]'
	out += handling_requirement_text
	if description != '':
		out += '\n'+description
	out += SettingsGlobals.bb_line
	out += effect.getRichDescription()
	out += SettingsGlobals.bb_line
	out += '\n[color=yellow] Uses: %s/%s' % [durability,max_durability]+'[/color] '
	out += '('+ str(repair_cost)+ OverworldGlobals.insertTextureCode(repair_item.icon)+')'
	return out

func getGeneralInfo():
	var out = ''
	if value > 0:
		out += '[img]res://images/sprites/trade_slip.png[/img]%s	' % value
	out += '[img]res://images/sprites/icon_durability.png[/img]%s/%s	' % [durability,max_durability]
#	if use_requirement['handling'] > 0:
#		out += '[img]res://images/sprites/circle_filled.png[/img] %s' % use_requirement['handling']
	return out
