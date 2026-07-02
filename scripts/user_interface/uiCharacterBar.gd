extends Control
class_name CharacterBar

@onready var character_name = $Healthbar/Name
@onready var character_portrait = $CharacterPortrait/CharacterFace
@onready var character_background = $CharacterPortrait
@onready var character_frame = $CharacterFrame
@onready var character_health = $Healthbar
@export var right_aligned:bool=false

func _ready():
	if right_aligned:
		#character_health.position.x = 2
		character_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		character_background.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT,true)
		character_frame.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT,true)
		#character_background.hide()

func setCharacter(combatant:ResPlayerCombatant):
	if combatant == null:
		return
	
	if combatant.preferred_alias != '':
		character_name.text = combatant.preferred_alias
	else:
		character_name.text = combatant.name.split(' ')[0]
	character_portrait.texture = combatant.character_portrait
	character_health.value = combatant.stat_values['health']
	character_health.max_value = combatant.getMaxHealth()
	#OverworldGlobals.party_damaged.connect(setHealthValue.bind(combatant.stat_values['health']))
	if !combatant.health_changed.is_connected(setHealthValue):
		combatant.health_changed.connect(setHealthValue)
	setHealthValue(combatant)

func setHealthValue(combatant):
	character_health.value = combatant.stat_values['health']
	character_health.max_value = combatant.getMaxHealth()
#character_health.max_value = combatant.getMaxHealth()
