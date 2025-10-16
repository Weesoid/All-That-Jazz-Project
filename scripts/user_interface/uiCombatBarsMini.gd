extends Control
class_name CombatBarsMini

@onready var fader_bar = $HealthBarFader
@onready var fader_animator = $HealthBarFader/AnimationPlayer
@onready var health_bar = $HealthBar
@onready var status_effects = $HealthBar/PermaStatusEffectContainer
@onready var selector = $Selector
@onready var prompts = $Marker2D
@onready var health_bar_fader = $HealthBarFader
@onready var action_texture = $Selector/ActionTexture
var attached_combatant: ResPlayerCombatant
var added_lingers = []
var previous_value
var default_action_pos: Vector2

func _ready():
	default_action_pos = action_texture.position
	CombatGlobals.manual_call_indicator.connect(manualCallIndicator)
	updateStatusEffects()

func setCombatant(combatant:ResPlayerCombatant):
	#print(self ,': setting to ', combatant)
	if !combatant.initialized:
		combatant.initializeCombatant(false)
	attached_combatant = combatant
	previous_value = attached_combatant.stat_values['health']
	updateBars()
	updateStatusEffects()

func setActionTexture(texture: Texture):
	var tween = create_tween().set_parallel()
	action_texture.scale = Vector2(1,1)
	action_texture.position += Vector2(0,-8) 
	action_texture.modulate = Color.TRANSPARENT
	tween.tween_property(action_texture,'position', default_action_pos,0.2)
	tween.tween_property(action_texture,'modulate', Color.WHITE,0.2)
	action_texture.texture = texture
	action_texture.show()

func unsetActionTexture():
	action_texture.texture = null
	action_texture.hide()

func pulseActionTexture(reset_view:bool=true):
	if action_texture.texture == null:
		return
	
	var tween = create_tween().chain()
	tween.tween_property(action_texture,'scale', Vector2(0,0),0.1).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	if reset_view:
		await tween.finished
		setActionTexture(action_texture.texture)

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
	health_bar.get_node('ProgressBarTrueValues').show()
#	if get_parent().texture != null:
#		get_parent().self_modulate = Color.YELLOW

func stopHighlight():
	health_bar.get_node('ProgressBarTrueValues').hide()
#	if get_parent().texture != null:
#		get_parent().self_modulate = Color.WHITE

func animateFaderBar(prev_val, value):
	if prev_val == value:
		return
	
	health_bar_fader.max_value = attached_combatant.getMaxHealth()
	health_bar_fader.value = prev_val
	if prev_val > value:
		health_bar_fader.modulate = Color.YELLOW
	elif prev_val < value:
		health_bar_fader.modulate = Color.GREEN
	health_bar_fader.modulate = Color.ORANGE
	await get_tree().create_timer(0.5).timeout
	var tween = create_tween().set_parallel(true)
	tween.tween_method(setFaderBarValue, prev_val, value, 0.3).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(health_bar_fader, 'modulate', Color.BLACK, 0.4)

func setFaderBarValue(value):
	health_bar_fader.value = value

func _on_health_bar_value_changed(value):
	animateFaderBar(previous_value, attached_combatant.stat_values['health'])
	previous_value = health_bar.value


func _on_selector_pressed():
	if action_texture.texture != null:
		pulseActionTexture()
