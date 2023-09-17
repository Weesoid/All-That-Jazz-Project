# Rename this to gblPlayerData
extends Node

var INVENTORY: Array[ResItem] = [] # Refactor into list with limit
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

signal quest_completed(quest)
signal quest_added
signal quest_objective_completed
signal quest_objective_failed
signal added_item_to_inventory

func _ready():
	EQUIPPED_ARROW = load("res://resources/items/Arrow.tres")
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
func addItemToInventory(item_name: String, count=1):
	var item = load("res://resources/items/"+item_name+".tres")
	assert(item!=null, "Item not found!")
	addItemResourceToInventory(item, count)

func addItemResourceToInventory(item: ResItem, count=1):
	if item is ResStackItem and INVENTORY.has(item):
		INVENTORY[INVENTORY.find(item)].STACK += count
	elif item is ResStackItem:
		if count != 1: 
			item.STACK = count
		INVENTORY.append(item)
	else:
		INVENTORY.append(item.duplicate())
	added_item_to_inventory.emit()
	PlayerGlobals.INVENTORY.sort_custom(func sortByName(a, b): return a.NAME < b.NAME)
	
	var inventory_prompt = preload("res://scenes/user_interface/InventoryUpdate.tscn").instantiate()
	var y_placement = 0
	for child in OverworldGlobals.getPlayer().player_camera.get_children():
		y_placement -= 23
	inventory_prompt.global_position += Vector2(0, y_placement)
	OverworldGlobals.getPlayer().player_camera.add_child(inventory_prompt)
	inventory_prompt.get_node("Label").text = '+ %s x%s' % [item.NAME, count]
	inventory_prompt.get_node("AnimationPlayer").play('Show')
	await inventory_prompt.get_node("AnimationPlayer").animation_finished
	inventory_prompt.queue_free()
	

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
		for stat in combatant.BASE_STAT_VALUES.keys():
			combatant.BASE_STAT_VALUES[stat] += combatant.STAT_GROWTH_RATES[stat] ** (PARTY_LEVEL - 1)

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
# QUEST MANAGEMENT
#********************************************************************************
func checkQuestsForCompleted():
	var ongoing_quests = QUESTS.filter(func getOngoing(quest): return !quest.COMPLETED)
	
	for quest in ongoing_quests:
		quest.isCompleted()

func updateObjectivePrompt(quest: ResQuest):
	var prompt = preload("res://scenes/user_interface/PromptQuest.tscn").instantiate()
	
	OverworldGlobals.getPlayer().player_camera.add_child(prompt)
	prompt.setTitle(quest.NAME)
	prompt.playAnimation('update_objective')
	await prompt.animator.animation_finished
	prompt.queue_free()

func promptQuestCompleted(quest: ResQuest):
	var prompt = preload("res://scenes/user_interface/PromptQuest.tscn").instantiate()
	
	OverworldGlobals.getPlayer().player_camera.add_child(prompt)
	prompt.setTitle(quest.NAME)
	prompt.setStatus("Quest Completed:")
	prompt.playAnimation('show_quest')

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
		PlayerGlobals.quest_objective_completed.emit()

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
	print('Attempting to get quest')
	for quest in QUESTS:
		if quest.NAME == quest_name: 
			print('FOUND: ', quest.NAME)
			return quest
	
	print('Returning null')
	return null
