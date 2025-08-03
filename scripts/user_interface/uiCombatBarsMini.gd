extends Control
class_name CombatBarsMini

@onready var fader_bar = $HealthBarFader
@onready var fader_animator = $HealthBarFader/AnimationPlayer
@onready var health_bar = $HealthBar
@onready var status_effects = $HealthBar/PermaStatusEffectContainer
@onready var selector = $Selector
@onready var prompts = $Marker2D
var attached_combatant: ResPlayerCombatant
var rest_sprite: Sprite2D
var highlight_tween: Tween
var added_lingers = []

func _ready():
	CombatGlobals.manual_call_indicator.connect(manualCallIndicator)
	updateStatusEffects()
	highlight_tween = create_tween().set_loops()
	highlight_tween.stop()

func manualCallIndicator(combatant: ResCombatant, text: String, animation: String):
	if attached_combatant == combatant:
		var secondary_indicator = load("res://scenes/user_interface/SecondaryIndicator.tscn").instantiate()
		var y_placement = 0
		for child in prompts.get_children():
			y_placement -= 8
		prompts.add_child(secondary_indicator)
		secondary_indicator.playAnimation(prompts.global_position+Vector2(0,y_placement), text, animation)

func _process(_delta):
	updateBars()
	#updateStatusEffects()

func updateBars():
	health_bar.max_value = int(attached_combatant.base_stat_values['health'])
	health_bar.value = int(attached_combatant.stat_values['health'])

func updateStatusEffects():
	#for child in status_effects.get_children():
	#	child.queue_free()
	#added_lingers = []
	#await get_tree().process_frame
	for linger_effect in attached_combatant.lingering_effects:
		if added_lingers.has(linger_effect):
			continue
		
		var effect: ResStatusEffect = CombatGlobals.loadStatusEffect(linger_effect)
		var icon = TextureRect.new()
		icon.texture = effect.texture
		icon.tooltip_text = effect.name+': '+effect.description
		status_effects.add_child(icon)
		added_lingers.append(linger_effect)

func highlightCombatant():
	if !highlight_tween.is_running():
		highlight_tween.tween_property(rest_sprite,'self_modulate', Color.YELLOW, 1.0).from(Color.WHITE)
		highlight_tween.play()

func stopHighlight():
	if highlight_tween.is_running():
		highlight_tween.stop()
	rest_sprite.self_modulate = Color.WHITE
