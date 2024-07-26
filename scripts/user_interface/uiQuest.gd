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
		button.focus_entered.connect(
			func setQuest():
				selected_quest = quest
				run_once = true
				)
		if quest.COMPLETED:
			completed_quests.add_child(button)
		else:
			ongoing_quests.add_child(button)
	OverworldGlobals.setMenuFocus(ongoing_quests)

func setQuestInfo():
	clearQuestInfo()
	
	title.text = selected_quest.NAME
	description.text = selected_quest.DESCRIPTION
	
	for objectve in selected_quest.OBJECTIVES:
		if objectve.ACTIVE:
			var objective_description = Label.new()
			objective_description.custom_minimum_size.x = objectives_container.size.x
			objective_description.text = str("* ", objectve.DESCRIPTION)
			objective_description.autowrap_mode = 3
			if objectve.COMPLETED:
				objective_description.self_modulate.a = 0.5
			if run_once and objectve.ACTIVE:
				objective_scroller.add_child(objective_description)
	
	run_once = false

func clearQuestInfo():
	title.text = ""
	description.text = ""
	for child in objective_scroller.get_children():
		child.queue_free()

func _unhandled_input(_event):
	if Input.is_action_just_pressed('ui_tab_right') and quests_containter.current_tab + 1 < quests_containter.get_tab_count():
		quests_containter.current_tab += 1
	elif Input.is_action_just_pressed('ui_tab_left') and quests_containter.current_tab - 1 >= 0:
		quests_containter.current_tab -= 1

func _on_quest_container_tab_changed(tab):
	match tab:
		0: OverworldGlobals.setMenuFocus(ongoing_quests)
		1: OverworldGlobals.setMenuFocus(completed_quests)
