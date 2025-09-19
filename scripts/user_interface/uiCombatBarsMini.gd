extends Control
class_name CombatBarsMini

@onready var fader_bar = $HealthBarFader
@onready var fader_animator = $HealthBarFader/AnimationPlayer
@onready var health_bar = $HealthBar
@onready var status_effects = $HealthBar/PermaStatusEffectContainer
@onready var selector = $Selector
@onready var prompts = $Marker2D
var attached_combatant: ResPlayerCombatant
#var highlight_tween: Tween
var added_lingers = []

func _ready():
	CombatGlobals.manual_call_indicator.connect(manualCallIndicator)
	updateStatusEffects()
#	highlight_tween = create_tween().set_loops()
#	highlight_tween.stop()

func manualCallIndicator(combatant: ResCombatant, text: String, animation: String):
	if attached_combatant == combatant:
		var secondary_indicator = load("res://scenes/user_interface/SecondaryIndicator.tscn").instantiate()
		var y_placement = 0
		for child in prompts.get_children():
			y_placement -= 8
		prompts.add_child(secondary_indicator)
		secondary_indicator.playAnimation(prompts.global_position+Vector2(0,y_placement), text, animation)

func _process(_delta):
	if attached_combatant == null:
		return
	updateBars()

func updateBars():
	health_bar.max_value = int(attached_combatant.base_stat_values['health'])
	health_bar.value = int(attached_combatant.stat_values['health'])

func updateStatusEffects():
	if attached_combatant == null:
		return
	for linger_effect in attached_combatant.lingering_effects:
		if added_lingers.has(linger_effect):
			continue
		if linger_effect.contains('linger|'):
			linger_effect = linger_effect.split('|')[1].replace(' ','')
		
		status_effects.add_child(OverworldGlobals.createStatusEffectIcon(linger_effect,TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL))
		added_lingers.append(linger_effect)

func highlightCombatant():
	if get_parent().texture != null:
		get_parent().self_modulate = Color.YELLOW

func stopHighlight():
	if get_parent().texture != null:
		get_parent().self_modulate = Color.WHITE
