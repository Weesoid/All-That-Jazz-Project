# Rename this to gblPlayerData
extends Node


var INVENTORY: Array[ResItem] = [] # Refactor into list with limit
var KNOWN_RECIPES: Array[ResRecipe] = []
var KNOWN_POWERS: Array[ResPower] = []
var CURRENCY = 0
var POWER: GDScript
var EQUIPPED_ARROW: ResProjectileAmmo
var PARTY_LEVEL = 1
var CURRENT_EXP = 0

func _ready():
	EQUIPPED_ARROW = load("res://resources/items/itmArrow.tres")
	
	KNOWN_RECIPES.append(load("res://resources/recipes/rcpArrow.tres"))
	
	KNOWN_POWERS.append(load("res://resources/powers/pwrAnchor.tres"))
	KNOWN_POWERS.append(load("res://resources/powers/pwrStealth.tres"))
	

func addItemToInventory(item_name: String):
	var item = load("res://resources/items/itm"+item_name+".tres")
	assert(item!=null, "Item not found!")
	addItemResourceToInventory(item)

func addItemResourceToInventory(item: ResItem):
	if item is ResStackItem and INVENTORY.has(item):
		INVENTORY[INVENTORY.find(item)].STACK += 1
	elif item is ResStackItem:
		if item.STACK != 1: item.STACK = 1
		INVENTORY.append(item)
	else:
		INVENTORY.append(item.duplicate())

func getItemFromInventory(item: ResItem):
	return INVENTORY[INVENTORY.find(item)]

func getItemWithName(item_name: String):
	for item in INVENTORY:
		if item.NAME == item_name:
			return item

func removeItemWithName(item_name: String):
	for item in INVENTORY:
		if item.NAME == item_name:
			INVENTORY.erase(item)
			return

func getUnstackableItemNames()-> Array:
	var out = []
	
	for item in INVENTORY:
		if !item is ResStackItem:
			out.append(item.NAME)
	
	return out

func getRecipe(item: ResRecipe):
	return KNOWN_RECIPES[KNOWN_RECIPES.find(item)]

func addExperience(experience: int):
	CURRENT_EXP += experience
	if CURRENT_EXP >= getRequiredExp():
		PARTY_LEVEL += 1
		CURRENT_EXP = 0
		levelUpCombatants()

func getRequiredExp() -> int:
	var baseExp = 100
	var expMultiplier = 1.25
	return int(baseExp * expMultiplier ** (PARTY_LEVEL - 1))

func levelUpCombatants():
	for combatant in OverworldGlobals.getCombatantSquad('Player'):
		for stat in combatant.BASE_STAT_VALUES.keys():
			combatant.BASE_STAT_VALUES[stat] += combatant.STAT_GROWTH_RATES[stat] ** (PARTY_LEVEL - 1)
