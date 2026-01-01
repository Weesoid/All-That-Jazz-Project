extends Control

@onready var base_container = $MarginContainer/HBoxContainer
@onready var points = $MarginContainer/Points
@export var combatant: ResPlayerCombatant #= preload("res://resources/combat/combatants_player/Willis.tres")
signal talent_interacted
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
	$MarginContainer/HBoxContainer/Path.hide()
	combatant = p_combatant
	for talent in combatant.talent_list.keys():
		if talent == 'base_talents':
			loadTalentList('BaseTalents', talent)
		else:
			loadTalentList('Path', talent)
			$MarginContainer/HBoxContainer/Path.show()

func loadTalentList(container:String, talent: String):
	getContainer(container,'title').text = talent.to_upper().replace('_',' ')
	var sorted_list = combatant.talent_list[talent]
	sorted_list = sorted_list.filter(func(talent): return talent.required_level <= PlayerGlobals.team_level)
	sorted_list.sort_custom(func(a,b): return a.required_level < b.required_level)
	for t in sorted_list:
		var button = OverworldGlobals.createTalentButton(t,combatant)
		button.pressed.connect(talentPressed.bind(t))
		button.pressed.connect(button.updateRank)
		button.held_press.connect(
			func():
				talentPressed(t,true)
				button.updateRank()
				)
		
		getContainer(container,'talents').add_child(button)
	updateAccesibility()

func updateAccesibility():
	for button in getContainer('Path','talents').get_children():
		if button.talent.required_talent == null: continue
		var has_requirement = combatant.active_talents.has(button.talent.required_talent)
		button.setDisabled(!has_requirement)
		if !has_requirement and combatant.active_talents.has(button.talent):
			talentDumped(button.talent,false)
			button.updateRank()

func getContainer(container_name:String, get_container:String):
	for item in base_container.get_children():
		if item.name == container_name:
			if get_container == 'title':
				return item.get_node('Title')
			elif get_container == 'talents':
				return item.get_node('CenterContainer').get_node('Talents')

func talentPressed(talent: ResTalent, max_out:bool=false, emit:bool=true):
	if Input.is_action_pressed("ui_sprint"): #and combatant.stat_points >= (talent.max_rank - combatant.active_talents.get(talent,0)):
		talentDumped(talent)
		return
	if combatant.stat_points < 1:
		pulsePoints()
		return
	if talent in combatant.active_talents.keys() and combatant.active_talents[talent]+1 > talent.max_rank:
		return
	var increase = 1
	if max_out:
		increase = talent.max_rank - combatant.active_talents.get(talent,0)
		if combatant.stat_points < increase:
			pulsePoints()
			return
	
	combatant.activateTalent(talent, increase)
	combatant.stat_points -= increase
	updatePointCount()
	updateAccesibility()
	if emit:
		talent_interacted.emit()

func talentDumped(talent: ResTalent,emit:bool=true):
	if !combatant.active_talents.has(talent):
		return
	
	combatant.stat_points += combatant.active_talents[talent]
	updatePointCount()
	combatant.removeTalent(talent)
	updateAccesibility()
	if emit:
		talent_interacted.emit()

func pulsePoints():
	var tween = get_tree().create_tween().set_parallel(false)
	tween.tween_property(points,'self_modulate',Color.RED,0.25)
	tween.tween_property(points,'self_modulate',Color.WHITE,0.25)

func updatePointCount():
	var current_count = combatant.stat_points
	if current_count > 0:
		points.modulate = Color.YELLOW
	else:
		points.modulate = Color.DIM_GRAY
	
	points.text = '  '+str(current_count)

