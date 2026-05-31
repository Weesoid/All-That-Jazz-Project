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
	combatant.equipped_weapon = self
	
	if !stat_modifications.is_empty():
		CombatGlobals.modifyStat(combatant, stat_modifications, name)

func unequip(combatant: ResCombatant):
	if !stat_modifications.is_empty():
		CombatGlobals.resetStat(combatant, name)
	
	combatant = null

func useDurability(combatant: ResCombatant):
	RepairableItem.useDurability(self)
	combatant.file_references['equipped_weapon'][1] = durability

func repair(repair_amount: int):
	RepairableItem.repair(self, repair_amount)

func canRepair(repair_amount:int):
	return RepairableItem.canRepair(self, repair_amount)

func isBroken():
	return RepairableItem.isBroken(self)

func canUse(combatant: ResCombatant):
	return combatant.stat_values['handling'] >= handling_requirement and !isBroken()

func getInformation():
	var handling_bb = '[img]res://images/sprites/circle_filled_small.png[/img]'
	var handling_requirement_text = '[center]'
	var out = '[center]'+UIGlobals.insertTextureCode(icon)+' '+name.to_upper()+'\n'
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
	out += '('+ str(repair_cost)+ UIGlobals.insertTextureCode(repair_item.icon)+')'
	return out

func getGeneralInfo():
	var out = ''
	if value > 0:
		out += '[img]res://images/sprites/trade_slip.png[/img]%s	' % value
	out += '[img]res://images/sprites/icon_durability.png[/img]%s/%s	' % [durability,max_durability]
#	if use_requirement['handling'] > 0:
#		out += '[img]res://images/sprites/circle_filled.png[/img] %s' % use_requirement['handling']
	return out
