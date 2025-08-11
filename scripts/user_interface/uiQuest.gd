extends Control

@onready var objectives_container = $MarginContainer/MarginContainer2/DescriptionPanel/Objectives
@onready var ongoing_quests = $QuestContainer/MarginContainer/VBoxContainer/VBoxContainer/Ongoing/VBoxContainer
@onready var completed_quests = $QuestContainer/MarginContainer/VBoxContainer/VBoxContainer/Completed/VBoxContainer
@onready var title = $MarginContainer/MarginContainer2/DescriptionPanel/Title
@onready var description = $MarginContainer/MarginContainer2/DescriptionPanel/Description
@onready var objective_scroller = $MarginContainer/MarginContainer2/DescriptionPanel/Objectives/VBoxContainer

var selected_quest: ResQuest
var run_once = true

func _process(_delta):
	if selected_quest != null and run_once:
		setQuestInfo()

func _ready():
	for quest in QuestGlobals.quests:
		var button = OverworldGlobals.createCustomButton()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = str(quest.name)
		button.focus_entered.connect(
			func setQuest():
				selected_quest = quest
				run_once = true
				#setQuestInfo()
				)
		if quest.completed:
			completed_quests.add_child(button)
		else:
			ongoing_quests.add_child(button)
	#await get_tree().process_frame
	#OverworldGlobals.setMenuFocus(ongoing_quests)

func setQuestInfo():
	clearQuestInfo()
	
	title.text = selected_quest.name
	description.text = selected_quest.description
	
	for objectve in selected_quest.objectives:
		if objectve.active:
			var objective_description = Label.new()
			#objective_description.custom_minimum_size.x = objectives_container.size.x
			objective_description.text = str("* ", objectve.description)
			#objective_description.autowrap_mode = 3
			if objectve.completed:
				objective_description.self_modulate.a = 0.5
			if run_once and objectve.active:
				objective_scroller.add_child(objective_description)
	
	run_once = false

func clearQuestInfo():
	title.text = ""
	description.text = ""
	for child in objective_scroller.get_children():
		child.queue_free()

func _on_quest_container_tab_changed(tab):
	match tab:
		0: OverworldGlobals.setMenuFocus(ongoing_quests)
		1: OverworldGlobals.setMenuFocus(completed_quests)
