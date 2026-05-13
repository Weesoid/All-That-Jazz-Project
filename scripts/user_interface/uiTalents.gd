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

func addTalentButton(talent, combatant):
	var button = OverworldGlobals.createTalentButton(talent,combatant)
	button.pressed.connect(talentPressed.bind(talent))
	button.held_press.connect(talentPressed.bind(talent,true))
	button.pressed.connect(button.updateRank)
	button.held_press.connect(button.updateRank)
	button.pressed.connect(func(): talent_interacted.emit(combatant))
	button.held_press.connect(func(): talent_interacted.emit(combatant))
	return button

func talentPressed(talent: ResTalent, max_out:bool=false, emit:bool=true):
	var current_rank = combatant.getTalentData(talent,'rank',0)
	var rank_up = 1 if !max_out else talent.max_rank - current_rank
	if rank_up*talent.cost > combatant.stat_points and max_out:
		rank_up = floor(combatant.stat_points/talent.cost)
	var cost = talent.cost * rank_up
	
	if Input.is_action_pressed("ui_sprint"):
		talentDumped(talent)
		return
	if !canAddTalent(talent, rank_up):
		return
	
	combatant.activateTalent(talent, rank_up)
#	updatePointCount()
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
	
	#combatant.stat_points += combatant.active_talents[talent]['cost']*combatant.active_talents[talent]['rank']
#	updatePointCount()
	combatant.removeTalent(talent)
	#updateAccesibility()
	if emit:
		talent_interacted.emit()

#func pulsePoints():
#	var tween = get_tree().create_tween().set_parallel(false)
#	tween.tween_property(points,'self_modulate',Color.RED,0.25)
#	tween.tween_property(points,'self_modulate',Color.WHITE,0.25)
#
#func updatePointCount():
#	var current_count = combatant.stat_points
#	if current_count > 0:
#		points.modulate = Color.YELLOW
#	else:
#		points.modulate = Color.DIM_GRAY
#
#	points.text = '  '+str(current_count)

