class_name StatusEffect

@export var NAME: String
@export var ANIMATION_NAME: String
@export var STATUS_SCRIPT_NAME: String
@export var DURATION: int

var TARGETABLE
var STATUS_SCRIPT
var ANIMATION

signal status_done

func initializeStatus():
	STATUS_SCRIPT = load(str("res://assets/scripts/ability_scripts/"+STATUS_SCRIPT_NAME+".gd"))
	ANIMATION = load(str("res://assets/scene_assets/animations/abilities/"+ANIMATION_NAME+".tscn")).instantiate()
		
func tick(afflicted_combatant: Combatant):
	if DURATION != 0:
		getAnimator().play('Tick')
		STATUS_SCRIPT.applyEffects(afflicted_combatant)
	else:
		getAnimator().play('Fade')
		status_done.emit()
		
	DURATION -= 1
	
func getAnimator()-> AnimationPlayer:
	return ANIMATION.get_node('AnimationPlayer')
	
func get_self():
	return self
	
