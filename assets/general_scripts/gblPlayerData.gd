# Rename this to gblPlayerData
extends Node

var INVENTORY: Array[ResItem] = [] # Refactor into list with limit
var PARTY_LEVEL = 1
var CURRENT_EXP = 0

func addItemToInventory(item_name: String):
	var item = load("res://assets/item_resources/itm"+item_name+".tres")
	assert(item!=null, "Item not found!")
	if item is ResConsumable and INVENTORY.has(item):
		INVENTORY[INVENTORY.find(item)].STACK += 1
	elif item is ResConsumable:
		INVENTORY.append(item)
	else:
		INVENTORY.append(item.duplicate())
	
func getItemFromInventory(item: ResItem):
	return INVENTORY[INVENTORY.find(item)]

func addExperience(experience: int):
	CURRENT_EXP += experience
	if CURRENT_EXP >= getRequiredExp():
		PARTY_LEVEL += 1
		CURRENT_EXP = 0
		levelUpCombatants()

func getRequiredExp() -> int:
	var baseExp = 15
	var expMultiplier = 1.2
	return int(baseExp * expMultiplier ** (PARTY_LEVEL - 1))

func levelUpCombatants():
	for combatant in OverworldGlobals.getCombatantSquad('Player'):
		for stat in combatant.BASE_STAT_VALUES.keys():
			combatant.BASE_STAT_VALUES[stat] += combatant.STAT_GROWTH_RATES[stat] ** (PARTY_LEVEL - 1)
