extends Resource
class_name ResStatusEffect

@export var NAME: String
@export var ANIMATION_NAME: String
@export var STATUS_SCRIPT_NAME: String
@export var ICON_NAME: String
@export var MAX_DURATION: int
@export var MAX_RANK: int
@export var APPLY_ONCE: bool

var duration
var current_rank
var afflicted_combatant: ResCombatant
var ICON: TextureRect
var TARGETABLE
var STATUS_SCRIPT
var ANIMATION

func initializeStatus():
	STATUS_SCRIPT = load(str("res://assets/scripts/ability_scripts/"+STATUS_SCRIPT_NAME+".gd"))
	duration = MAX_DURATION
	ICON = TextureRect.new()
	ICON.texture = load(str("res://assets/media/icons/"+ICON_NAME+".png"))
	
func addStatusEffectIcon():
	afflicted_combatant.getStatusBar().get_node("StatusContainer").add_child(ICON)
	current_rank = 1
	
func tick():
	duration -= 1
	if duration != 0 and !afflicted_combatant.isDead():
		#getAnimator().play('Tick')
		STATUS_SCRIPT.applyEffects(afflicted_combatant, self)
		APPLY_ONCE = false
	else:
		afflicted_combatant.getStatusBar().get_node("StatusContainer").remove_child(ICON)
		STATUS_SCRIPT.endEffects(afflicted_combatant)
		afflicted_combatant.STATUS_EFFECTS.erase(self)
	
func getAnimator()-> AnimationPlayer:
	return ANIMATION.get_node('AnimationPlayer')
	
func get_self():
	return self
	
