extends Node

var INVENTORY = {}
var PARTY_LEVEL = 1
var CURRENT_EXP = 0

func addItemToInventory(item_name: String):
	var item = load("res://assets/item_resources/itm"+item_name+".tres")
	if item is ResConsumable:
		if INVENTORY.has(item.NAME):
			INVENTORY[item.NAME].STACK += 1
		else:
			INVENTORY[item.NAME] = item
	elif item is ResWeapon or item is ResArmor:
		INVENTORY[item.NAME] = item
	print('Inv is now: ', INVENTORY)
	

func addExperience(experience: int):
	CURRENT_EXP += experience
	print('current: ', CURRENT_EXP)
	print('required: ', getRequiredExp())
	if CURRENT_EXP >= getRequiredExp():
		PARTY_LEVEL += 1
		CURRENT_EXP = 0
		levelUpCombatants()

func getRequiredExp() -> int:
	var baseExp = 15
	var expMultiplier = 1.2
	return int(baseExp * expMultiplier ** (PARTY_LEVEL - 1))

func levelUpCombatants():
	print('level up!')
	for combatant in OverworldGlobals.getCombatantSquad('Player'):
		for stat in combatant.BASE_STAT_VALUES.keys():
			combatant.BASE_STAT_VALUES[stat] += combatant.STAT_GROWTH_RATES[stat] ** (PARTY_LEVEL - 1)
