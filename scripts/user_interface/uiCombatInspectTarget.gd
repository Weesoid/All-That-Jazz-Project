extends Node2D

@onready var combatant_name = $CombatantName
@onready var bottom_menu = $Stats
@onready var side_menu = $Description
@onready var status_effects = $StatusEffects

var subject

func _process(_delta):
	if subject is ResCombatant:
		combatant_name.text = subject.NAME
		bottom_menu.text = subject.getStringCurrentStats()
		side_menu.text = subject.DESCRIPTION
		getStatusEffectInfo(subject)

func getStatusEffectInfo(combatant: ResCombatant):
	status_effects.text = ''
	if combatant.STATUS_EFFECTS.is_empty():
		return
	
	for effect in combatant.STATUS_EFFECTS:
		if effect.TEXTURE != null:
			var texture_path = effect.TEXTURE.resource_path
			status_effects.text += "\n[img]%s[/img] %s\n" % [texture_path, effect.DESCRIPTION]
		else:
			status_effects.text += "\n%s\n" % [effect.DESCRIPTION]
