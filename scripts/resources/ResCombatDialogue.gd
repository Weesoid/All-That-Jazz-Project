extends Resource
class_name ResCombatDialogue

@export var turn_dialogue: DialogueResource 
@export var win_dialogue: DialogueResource
@export var lose_dialogue: DialogueResource
@export var ability_dialogue: DialogueResource
@export var combatant_stat_dialogue: DialogueResource

@export var turn_condition: int
@export var ability_condition: ResAbility
@export var combatant_name: String
@export var combatant_stat_condition: String
@export var combatant_stat_value: float

var combatant_condition: ResCombatant
var dialogue_node

func initializeDialogue(combatants: Array[ResCombatant]):
	dialogue_node = preload("res://scenes/components/CombatDialogue.tscn").instantiate()
	
	for combatant in combatants:
		if combatant.NAME == combatant_name:
			combatant_condition = combatant
	
	dialogue_node.turn_dialogue = turn_dialogue
	dialogue_node.win_dialogue = win_dialogue
	dialogue_node.lose_dialogue = lose_dialogue
	dialogue_node.ability_dialogue = ability_dialogue
	dialogue_node.combatant_stat_dialogue = combatant_stat_dialogue
	dialogue_node.turn_condition = turn_condition
	dialogue_node.ability_condition = ability_condition
	dialogue_node.combatant_condition = combatant_condition
	dialogue_node.combatant_stat_condition = combatant_stat_condition
	dialogue_node.combatant_stat_value = combatant_stat_value
	CombatGlobals.getCombatScene().add_child(dialogue_node)
