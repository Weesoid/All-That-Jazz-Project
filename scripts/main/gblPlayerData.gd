# Rename this to gblPlayerData
extends Node

var INVENTORY: Array[ResItem] = [] # Refactor into list with limit
var STORAGE: Array[ResItem] = []
var CURRENT_CAPACITY = 0
var MAX_CAPACITY = 100
var KNOWN_RECIPES: Array[ResRecipe] = []
var KNOWN_POWERS: Array[ResPower] = []
var QUESTS: Array[ResQuest]
var TEAM: Array[ResPlayerCombatant]
var CURRENCY = 0
var POWER: GDScript
var EQUIPPED_ARROW: ResProjectileAmmo
var PARTY_LEVEL = 1
var CURRENT_EXP = 0
var FOLLOWERS: Array[NPCFollower] = []

signal level_up
signal quest_completed(quest)
signal quest_objective_completed(objective)
signal quest_added
signal added_item_to_inventory

func _ready():
	CURRENCY = 100
	# Fix later
	EQUIPPED_ARROW = load("res://resources/items/Arrow.tres")
	EQUIPPED_ARROW.STACK = 0
	KNOWN_RECIPES.append(load("res://resources/recipes/ArrowRecipe.tres"))
	KNOWN_POWERS.append(load("res://resources/powers/Anchor.tres"))
	KNOWN_POWERS.append(load("res://resources/powers/Stealth.tres"))
	quest_objective_completed.connect(checkQuestsForCompleted)
	quest_completed.connect(promptQuestCompleted)
	
	TEAM.append(preload("res://resources/combatants/p_PrototypeA.tres"))
	TEAM.append(preload("res://resources/combatants/p_PPrototypeB.tres"))
	initializeBenchedTeam()

func initializeBenchedTeam():
	if PlayerGlobals.TEAM.is_empty():
		return
	
	for member in TEAM:
		if !member.initialized:
			member.initializeCombatant()
			member.SCENE.free()

#********************************************************************************
# INVENTORY MANAGEMENT
#********************************************************************************
func addItem(item_name: String, count=1, unit=INVENTORY):
	var item = load("res://resources/items/"+item_name+".tres")
	assert(item!=null, "Item not found!")
	addItemResource(item, count, unit)

func addItemResource(item: ResItem, count=1, unit=INVENTORY):
	if unit == INVENTORY and !canAdd(item, count) or count <= 0:
		return
	
	if item is ResStackItem and unit.has(item):
		unit[unit.find(item)].add(count)
	elif item is ResStackItem:
		if item.STACK <= 0: item.STACK = 1
		item.add(count-1, false)
		unit.append(item)
		OverworldGlobals.getPlayer().prompt.showPrompt('Added [color=yellow]%s[/color] to %s.' % [item, getStorageUnitName(unit)])
	
	elif item is ResEquippable:
		unit.append(item)
		OverworldGlobals.getPlayer().prompt.showPrompt('Added [color=yellow]%s[/color] to %s.' % [item, getStorageUnitName(unit)])
	
	if unit == INVENTORY: refreshWeights()
	added_item_to_inventory.emit()
	unit.sort_custom(func sortByName(a, b): return a.NAME < b.NAME)

func hasItem(item_name, unit=INVENTORY):
	for item in unit:
		if item.NAME == item_name: return true
	
	return false

func getItem(item: ResItem, unit=INVENTORY):
	return unit[unit.find(item)]

func getItemWithName(item_name: String, unit=INVENTORY):
	for item in unit:
		if item.NAME == item_name:
			return item

func removeItemWithName(item_name: String, count=1, unit=INVENTORY):
	for item in unit:
		if item.NAME == item_name:
			removeItemResource(item,count)

func removeItemResource(item, count=1, unit=INVENTORY):
	if count == 0:
		return
	
	if item is ResEquippable:
		if item.isEquipped(): item.unequip()
		unit.erase(item)
		OverworldGlobals.getPlayer().prompt.showPrompt('[color=yellow]%s[/color] removed from %s.' % [item, getStorageUnitName(unit)])
	
	elif item is ResStackItem:
		item.take(count)
		if !item is ResProjectileAmmo:
			OverworldGlobals.getPlayer().prompt.showPrompt('[color=yellow]x%s %s[/color] removed from %s.' % [count, item.NAME, getStorageUnitName(unit)])
		if item.STACK <= 0: 
			OverworldGlobals.getPlayer().prompt.showPrompt('[color=yellow]%s[/color] is depleted!' % [item.NAME])
			unit.erase(item)
	
	if unit == INVENTORY: refreshWeights()

func refreshWeights():
	CURRENT_CAPACITY = 0
	for item in INVENTORY:
		CURRENT_CAPACITY += item.WEIGHT

func incrementStackItem(item_name: String, count):
	for item in INVENTORY:
		if item.NAME == item_name:
			item.add(count)
			added_item_to_inventory.emit()
			refreshWeights()

func createGhostStack(item: ResStackItem, count=1, transfer=true):
	for i in STORAGE:
		if i.NAME == item.NAME: 
			if transfer: removeItemResource(item, count)
			OverworldGlobals.getPlayer().prompt.showPrompt('Added [color=yellow]x%s %s[/color] to Storage.' % [count, item.NAME])
			i.add(count, false)
			return
	
	var ghost_stack = ResGhostStackItem.new(item)
	if transfer: removeItemWithName(item.NAME, count)
	addItemResource(ghost_stack, count, STORAGE)

func takeFromGhostStack(item: ResGhostStackItem, count, transfer_to_storage=false):
	if !canAdd(item.REFERENCE_ITEM, count, transfer_to_storage):
		return
	
	for stackable in STORAGE:
		if stackable.NAME == item.NAME:
			removeItemResource(stackable,count,STORAGE)
	
	if hasItem(item.NAME):
		incrementStackItem(item.NAME, count)
	else:
		addItemResource(item.REFERENCE_ITEM, count)

func transferItem(item: ResItem, count: int, from: Array[ResItem], to: Array[ResItem]):
	if item is ResStackItem and count <= 0:
		return
	if item is ResStackItem and from == INVENTORY and to == STORAGE:
		createGhostStack(item, count)
		return
	elif item is ResStackItem and from == STORAGE and to == INVENTORY:
		takeFromGhostStack(item, count)
		return
	
	if from.has(item):
		removeItemResource(item, count, from)
		addItemResource(item, count, to)

func canAdd(item, count=1, transfer_storage=true, show_prompt=true):
	if item is ResEquippable and (hasItem(item.NAME) or hasItem(item.NAME, STORAGE)):
		if show_prompt: OverworldGlobals.getPlayer().prompt.showPrompt('Already have [color=yellow]%s[/color].' % [item])
		return false
	if item is ResEquippable and item.WEIGHT + CURRENT_CAPACITY > MAX_CAPACITY:
		if show_prompt: OverworldGlobals.getPlayer().prompt.showPrompt('[color=yellow]%s[/color] not added! Your Inventory is full.' % item)
		if transfer_storage:
			addItemResource(item,1,STORAGE)
		return false
	
	if item is ResStackItem and count <= 0:
		return
	if item is ResStackItem and (item.PER_WEIGHT * count) + CURRENT_CAPACITY > MAX_CAPACITY:
		if show_prompt: OverworldGlobals.getPlayer().prompt.showPrompt('[color=yellow]x%s %s[/color] not added! Your Inventory is full.' % [str(count), item.NAME])
		if transfer_storage:
			var feasible_count = determineFeasibleCount(item, count)
			addItemResource(item,feasible_count,INVENTORY)
			createGhostStack(item, count - feasible_count, false)
		return false	
	if item is ResStackItem and (item.STACK + count) > item.MAX_STACK:
		if show_prompt: OverworldGlobals.getPlayer().prompt.showPrompt('Max stack for [color=yellow]%s[/color] reached!' % item.NAME)
		if transfer_storage:
			var feasible_count = item.MAX_STACK - item.STACK
			addItemResource(item,feasible_count,INVENTORY)
			createGhostStack(item, count - feasible_count, false)
		return false
	
	return true

func determineFeasibleCount(item: ResStackItem, count: int):
	while (item.PER_WEIGHT * count) + CURRENT_CAPACITY > MAX_CAPACITY:
		count -= 1
	
	return count

func getStorageUnitName(unit: Array[ResItem]):
	match unit:
		INVENTORY: return 'Inventory'
		STORAGE: return 'Storage'

func getUnstackableItemNames()-> Array:
	var out = []
	
	for item in INVENTORY:
		if !item is ResStackItem:
			out.append(item.NAME)
	
	return out

func getRecipe(item: ResRecipe):
	return KNOWN_RECIPES[KNOWN_RECIPES.find(item)]

func repairItem(item: ResWeapon, repair_amount: int, free_repair=false):
	#if getItemWithName("Scrap Salvage") == null: 
	#	OverworldGlobals.getPlayer().prompt.showPrompt('Not enough [color=yellow]Scrap Salvage![/color]')
	if !free_repair and getItemWithName("Scrap Salvage").STACK >= repair_amount:
		removeItemWithName("Scrap Salvage", repair_amount)
		item.restoreDurability(repair_amount)
	elif free_repair:
		item.restoreDurability(repair_amount)
	else:
		OverworldGlobals.getPlayer().prompt.showPrompt('Not enough [color=yellow]Scrap Salvage![/color]')
		return

func repairAllItems():
	for item in INVENTORY:
		if !item is ResWeapon: continue
		item.restoreDurability(item.max_durability)

#********************************************************************************
# COMBATANT MANAGEMENT
#********************************************************************************
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
	for combatant in PlayerGlobals.TEAM:
		combatant.ABILITY_POINTS += 1
		for stat in combatant.BASE_STAT_VALUES.keys():
			combatant.BASE_STAT_VALUES[stat] += combatant.STAT_GROWTH_RATES[stat] ** (PARTY_LEVEL - 1)
	level_up.emit()

func addFollower(follower: NPCFollower):
	FOLLOWERS.append(follower)
	follower.FOLLOW_LOCATION = 20 * FOLLOWERS.size()

func removeFollower(follower_combatant: ResPlayerCombatant):
	for f in FOLLOWERS:
		if f.host_combatant == follower_combatant:
			FOLLOWERS.erase(f)
	
	var index = 1
	for f in FOLLOWERS:
		f.FOLLOW_LOCATION = 20 * index
		index += 1

func hasFollower(follower_combatant: ResPlayerCombatant):
	for f in FOLLOWERS:
		if f.host_combatant == follower_combatant:
			return true
	
	return false

#********************************************************************************
# QUEST MANAGEMENT (NOT IF ANY OVERTIME LAG HAPPENS, CONSIDER REWORKING QUESTS TO NODES) ...ehh you know what this might be fine...
#********************************************************************************
func checkQuestsForCompleted(objective: ResQuestObjective):
	var ongoing_quests = QUESTS.filter(func getOngoing(quest): return !quest.COMPLETED)
	
	for quest in ongoing_quests:
		if quest.getObjective(objective.NAME) != null and !objective.END_OBJECTIVE:
			OverworldGlobals.getPlayer().prompt.showPrompt('Quest updated: [color=yellow]%s[/color]' % quest.NAME, 5.0, "641011__metkir__crying-sound-0.mp3")
		
		quest.isCompleted()

func promptQuestCompleted(quest: ResQuest):
	var prompt = preload("res://scenes/user_interface/PromptQuest.tscn").instantiate()
	
	OverworldGlobals.getPlayer().player_camera.add_child(prompt)
	prompt.setTitle(quest.NAME)
	prompt.playAnimation('quest_complete')

func addQuest(quest_name: String):
	var prompt = preload("res://scenes/user_interface/PromptQuest.tscn").instantiate()
	var quest = load("res://resources/quests/%s/%s.tres" % [quest_name, quest_name])
	quest.initializeQuest()
	QUESTS.append(quest)
	quest_added.emit()
	
	OverworldGlobals.getPlayer().player_camera.add_child(prompt)
	prompt.setTitle(quest.NAME)
	prompt.playAnimation('show_quest')

func hasQuest(quest_name: String):
	if QUESTS.is_empty() or getQuest(quest_name) == null: 
		return false
	
	var quest = QUESTS[QUESTS.find(getQuest(quest_name))]
	return quest != null

func isQuestCompleted(quest_name: String):
	if QUESTS.is_empty(): return false
	var quest = QUESTS[QUESTS.find(getQuest(quest_name))]
	return quest.COMPLETED

func setQuestObjective(quest_name: String, quest_objective_name: String, set_to: bool):
	var objective = QUESTS[QUESTS.find(getQuest(quest_name))].getObjective(quest_objective_name)
	objective.FINISHED = set_to
	if set_to:
		quest_objective_completed.emit(objective)

func isQuestObjectiveEnabled(quest_name: String, quest_objective_name: String) -> bool:
	if QUESTS.is_empty() or getQuest(quest_name) == null:
		return false
	
	var objective = QUESTS[QUESTS.find(getQuest(quest_name))].getObjective(quest_objective_name)
	
	return objective.ENABLED and !objective.FINISHED

func isQuestObjectiveCompleted(quest_name: String, quest_objective_name: String) -> bool:
	if QUESTS.is_empty() or getQuest(quest_name) == null: 
		return false
	
	var objective = QUESTS[QUESTS.find(getQuest(quest_name))].getObjective(quest_objective_name)
	
	return objective.FINISHED

func isQuestObjectiveFailed(quest_name: String, quest_objective_name: String) -> bool:
	if QUESTS.is_empty() or getQuest(quest_name) == null:
		return false
	
	var objective = QUESTS[QUESTS.find(getQuest(quest_name))].getObjective(quest_objective_name)
	
	return objective.FAILED

func getQuest(quest_name: String)-> ResQuest:
	for quest in QUESTS:
		if quest.NAME == quest_name: 
			return quest
	
	return null
