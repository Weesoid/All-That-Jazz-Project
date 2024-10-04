extends Node

var toggle_sprint = true
var toggle_music = false

func doSprint()-> bool:
	return (Input.is_action_pressed("ui_sprint") and !SettingsGlobals.toggle_sprint) or (Input.is_action_just_pressed("ui_sprint") and SettingsGlobals.toggle_sprint) and !OverworldGlobals.getPlayer().sprinting

func stopSprint()-> bool:
	return (Input.is_action_just_released("ui_sprint") and !SettingsGlobals.toggle_sprint) or (Input.is_action_just_pressed("ui_sprint") and SettingsGlobals.toggle_sprint) and OverworldGlobals.getPlayer().sprinting
