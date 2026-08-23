extends Control

@onready var base_container = $MarginContainer/HBoxContainer
@onready var talent_buttons = $MarginContainer/HBoxContainer/BaseTalents/CenterContainer/Talents
@onready var points = $MarginContainer/Points

@export var combatant: ResPlayerCombatant #= preload("res://resources/combat/combatants_player/Willis.tres")
signal talent_interacted(combatant)

func loadTalents(p_combatant: ResPlayerCombatant, talent_tree_name:String='Talents'):
	for button in talent_buttons.get_children():
		button.queue_free()
	await get_tree().process_frame
	
	combatant = p_combatant
	for talent_tree in combatant.talent_trees:
		if talent_tree.name.to_lower() != talent_tree_name.to_lower(): continue
		for talent in talent_tree.talents:
			talent_buttons.add_child(addTalentButton(talent, combatant))
		break

func addTalentButton(talent, p_combatant):
	var button = UIGlobals.createTalentButton(talent,p_combatant)
	button.pressed.connect(talentPressed.bind(talent))
	button.held_press.connect(talentPressed.bind(talent,true))
	button.gui_input.connect(dumpTalent.bind(talent))
	button.pressed.connect(button.updateRank)
	button.held_press.connect(button.updateRank)
	button.gui_input.connect(button.updateRank.unbind(1))
	button.pressed.connect(func(): talent_interacted.emit(p_combatant))
	button.held_press.connect(func(): talent_interacted.emit(p_combatant))
	button.gui_input.connect(func(_input): talent_interacted.emit(p_combatant))
	return button

func dumpTalent(input: InputEvent, talent):
	if InputMap.action_has_event("ui_alternate_cancel", input) and input.is_pressed():
		talentDumped(talent)
	
func talentPressed(talent: ResTalent, max_out:bool=false, emit:bool=true):
	var current_rank = combatant.getTalentData(talent,'rank',0)
	var rank_up = 1 if !max_out else talent.max_rank - current_rank
	if rank_up*talent.cost > combatant.stat_points and max_out:
		rank_up = floor(float(combatant.stat_points)/float(talent.cost))
	
	if !canAddTalent(talent, rank_up):
		return
	
	combatant.activateTalent(talent, rank_up)
	if emit:
		talent_interacted.emit(combatant)

func canAddTalent(talent: ResTalent, add_ranks:int):
	var current_rank = combatant.getTalentData(talent,'rank',0)
	return current_rank+add_ranks <= talent.max_rank and \
		combatant.stat_points >= talent.cost*add_ranks and \
		add_ranks > 0

func talentDumped(talent: ResTalent,emit:bool=true):
	if !combatant.active_talents.has(talent):
		return
	combatant.removeTalent(talent)
	if emit:
		talent_interacted.emit(combatant)
