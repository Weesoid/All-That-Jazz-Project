extends Door

func interact():
	PlayerGlobals.addExperience(int(-0.15 * PlayerGlobals.getRequiredExp()), true)
	OverworldGlobals.changeMap(TO_SCENE_PATH, '0,0,0','SavePoint',true,true)

func _on_body_entered(body):
	if TOUCH_ENTER and body is PlayerScene and PlayerGlobals.isMapCleared(): 
		OverworldGlobals.changeMap(TO_SCENE_PATH, TO_COORDS)
	elif TOUCH_ENTER and body is PlayerScene:
		OverworldGlobals.showPlayerPrompt("You can't leave yet, there's a job to be done.")
