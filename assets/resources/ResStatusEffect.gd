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
	ICON = TextureRect.new()
	ICON.texture = load(str("res://assets/icons/"+ICON_NAME+".png"))
	STATUS_SCRIPT = load(str("res://assets/ability_scripts/"+STATUS_SCRIPT_NAME+".gd"))
	duration = MAX_DURATION
	
func addStatusEffectIcon():
	afflicted_combatant.getStatusBar().add_child(ICON)
	current_rank = 1
	
func tick():
	duration -= 1
	STATUS_SCRIPT.applyEffects(afflicted_combatant, self)
	APPLY_ONCE = false
	if duration == 0 or afflicted_combatant.isDead():
		afflicted_combatant.getStatusBar().remove_child(ICON)
		STATUS_SCRIPT.endEffects(afflicted_combatant)
		afflicted_combatant.STATUS_EFFECTS.erase(self)
	
func removeStatusEffect():
	afflicted_combatant.getStatusBar().remove_child(ICON)
	STATUS_SCRIPT.endEffects(afflicted_combatant)
	afflicted_combatant.STATUS_EFFECTS.erase(self)
	
func getAnimator()-> AnimationPlayer:
	return ANIMATION.get_node('AnimationPlayer')
	
