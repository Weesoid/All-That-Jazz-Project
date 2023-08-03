extends Control

@onready var animator = $AnimationPlayer
@onready var quest_status = $QuestStarted
@onready var quest_title = $QuestTitle
@onready var previous_objective = $PreviousObjective
@onready var current_objective = $CurrentObjective

func setTitle(title: String):
	quest_title.text = title

func setStatus(status: String):
	quest_status.text = status

func playAnimation(animation_name: String):
	animator.play("RESET")
	animator.play(animation_name)

func updateObjectives(completed_objective: String, new_objective: String):
	previous_objective.text = completed_objective
	current_objective.text = new_objective
