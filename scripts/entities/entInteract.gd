extends Area2D

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start"

func interact():
	OverworldGlobals.getPlayer().sprinting = false
	OverworldGlobals.showDialogueBox(dialogue_resource, dialogue_start)
