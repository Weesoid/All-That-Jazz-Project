extends Node2D
class_name CombatBarsMini

@onready var fader_bar = $HealthBarFader
@onready var fader_animator = $HealthBarFader/AnimationPlayer
@onready var health_bar = $HealthBar
@onready var status_effects = $HealthBar/PermaStatusEffectContainer

var attached_combatant: ResCombatant

func _ready():
	updateStatusEffects()

func _process(_delta):
	updateBars()
	#updateStatusEffects()

func updateBars():
	health_bar.max_value = int(attached_combatant.base_stat_values['health'])
	health_bar.value = int(attached_combatant.stat_values['health'])

func updateStatusEffects():
	for linger_effect in attached_combatant.lingering_effects:
		var effect: ResStatusEffect = CombatGlobals.loadStatusEffect(linger_effect)
		var icon = TextureRect.new()
		icon.texture = effect.texture
		icon.tooltip_text = effect.name+': '+effect.description
		status_effects.add_child(icon)
