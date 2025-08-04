extends PlayerScene
class_name PlayerBowOnly

func _input(_event):
	#name = 'Archie'
	
	# Sprint/bow handling
	if SettingsGlobals.doSprint():
		sprinting = true
	elif SettingsGlobals.stopSprint():
		sprinting = false
	if Input.is_action_just_pressed("ui_bow") and canDrawBow():
		if bow_draw_strength == 0: 
			bow_mode = !bow_mode
		elif bow_draw_strength > 0:
			undrawBow()
