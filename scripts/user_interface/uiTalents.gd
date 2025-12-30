extends Control


@onready var base_container = $MarginContainer/HBoxContainer
@onready var points = $MarginContainer/Points
@export var combatant: ResPlayerCombatant #= preload("res://resources/combat/combatants_player/Willis.tres")
var out:bool=false

#func _ready():
#	combatant.initializeCombatant(false)
#	await get_tree().process_frame
#	loadTalents(combatant)

func loadTalents(p_combatant: ResPlayerCombatant):
	for child in getContainer('BaseTalents','talents').get_children():
		child.queue_free()
		var body = CharacterBody2D.new()
		await child.tree_exited
	for child in getContainer('Path','talents').get_children():
		child.queue_free()
		var body = CharacterBody2D.new()
		await child.tree_exited
	
	combatant = p_combatant
	
	for talent in combatant.talent_list.keys():
		getContainer('BaseTalents','title').text = talent.to_upper().replace('_',' ')
		for t in combatant.talent_list[talent]:
			var button = OverworldGlobals.createTalentButton(t,combatant)
			button.pressed.connect(talentPressed.bind(t))
			button.pressed.connect(button.updateRank)
			button.held_press.connect(
				func():
					talentDumped(t)
					button.updateRank()
					)
			getContainer('BaseTalents','talents').add_child(button)
	for talent in combatant.talent_list.keys():
		getContainer('Path','title').text = talent.to_upper().replace('_',' ')
		for t in combatant.talent_list[talent]:
			var button = OverworldGlobals.createTalentButton(t,combatant)
			button.pressed.connect(talentPressed.bind(t))
			button.pressed.connect(button.updateRank)
			button.held_press.connect(
				func():
					talentDumped(t)
					button.updateRank()
					)
			getContainer('Path','talents').add_child(button)
	
	updatePointCount()

func getContainer(container_name:String, get_container:String):
	for item in base_container.get_children():
		if item.name == container_name:
			if get_container == 'title':
				return item.get_node('Title')
			elif get_container == 'talents':
				return item.get_node('CenterContainer').get_node('Talents')

func talentPressed(talent: ResTalent):
	if combatant.stat_points < 1 or (talent in combatant.active_talents.keys() and combatant.active_talents[talent]+1 > talent.max_rank):
		return
	
	combatant.activateTalent(talent)
	combatant.stat_points -= 1
	updatePointCount()
#	print(combatant.active_talents)
#	print(CombatGlobals.getStatChangeString(combatant.stat_values))
#	print(combatant.stat_modifiers)

func talentDumped(talent: ResTalent):
	if !combatant.active_talents.has(talent):
		return
	
	combatant.stat_points += combatant.active_talents[talent]
	updatePointCount()
	combatant.removeTalent(talent)
#	print(combatant.active_talents)
#	print(CombatGlobals.getStatChangeString(combatant.stat_values))
#	print(combatant.stat_modifiers)

func updatePointCount():
	var current_count = combatant.stat_points
	if current_count > 0:
		points.modulate = Color.YELLOW
	else:
		points.modulate = Color.DIM_GRAY
	
	points.text = '  '+str(current_count)

