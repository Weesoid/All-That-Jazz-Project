extends Control

@onready var quests_containter = $QuestContainer
@onready var objectives_container = $DescriptionPanel/Objectives

@onready var ongoing_quests = $QuestContainer/Ongoing/VBoxContainer
@onready var completed_quests = $QuestContainer/Completed/VBoxContainer
@onready var title = $DescriptionPanel/Title
@onready var description = $DescriptionPanel/Description
@onready var objectives_panel = $DescriptionPanel/Objectives
@onready var objective_scroller = $DescriptionPanel/Objectives/VBoxContainer

var selected_quest: ResQuest
var run_once = true

func _process(_delta):
	if selected_quest != null and run_once:
		setQuestInfo()

func _ready():
	for quest in QuestGlobals.QUESTS:
		var button = OverworldGlobals.createCustomButton()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = str(quest.NAME)
		button.custom_minimum_size.x = quests_containter.size.x
		button.mouse_entered.connect(
			func setQuest():
				selected_quest = quest
				run_once = true
				)
		if quest.COMPLETED:
			completed_quests.add_child(button)
		else:
			ongoing_quests.add_child(button)

func setQuestInfo():
	clearQuestInfo()
	
	title.text = selected_quest.NAME
	description.text = selected_quest.DESCRIPTION
	
	for objectve in selected_quest.OBJECTIVES:
		if objectve.ENABLED:
			var objective_description = Label.new()
			objective_description.custom_minimum_size.x = objectives_container.size.x
			objective_description.text = str("* ", objectve.DESCRIPTION)
			objective_description.autowrap_mode = 3
			if objectve.FINISHED:
				objective_description.self_modulate.a = 0.5
			if run_once and objectve.ENABLED:
				objective_scroller.add_child(objective_description)
		elif objectve.FAILED:
			var objective_description = Label.new()
			objective_description.custom_minimum_size.x = objectives_container.size.x
			objective_description.text = str("* ", objectve.DESCRIPTION)
			objective_description.autowrap_mode = 3
			objective_description.self_modulate =  Color(1, 0, 0, 0.3)
			if run_once:
				objective_scroller.add_child(objective_description)
	
	run_once = false

func clearQuestInfo():
	title.text = ""
	description.text = ""
	for child in objective_scroller.get_children():
		child.queue_free()
