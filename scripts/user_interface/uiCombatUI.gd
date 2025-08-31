extends Control
class_name CombatUI

const COMBAT_GEAR_ICON = preload("res://images/ability_icons/combat_gear.png")
const EMPTY_ABILITY_ICON = preload("res://images/ability_icons/invalid.png")
@onready var ability_buttons = $AbilityContainer
@onready var base_abilities = $AbilityContainer/BaseAbilities/BaseAbilities
@onready var tension_bar: CustomCountBar = $AbilityContainer/BaseAbilities/Tension/TensionBar
@onready var combat_scene = CombatGlobals.getCombatScene()
@onready var gear_button = $AbilityContainer/BaseAbilities/BaseAbilities/Gear
@onready var combat_log = $CombatLog
@onready var combat_log_animator = $CombatLog/AnimationPlayer
@onready var whole_ui_animator = $AnimationPlayer
@onready var escape_button = $EscapeButton
@onready var escape_chance = $EscapeButton/EscapeChance
@onready var escape_button_default_pos = escape_button.position
@onready var move_button = $AbilityContainer/BaseAbilities/BaseAbilities/Move
@onready var move_forward_button = $AbilityContainer/BaseAbilities/BaseAbilities/Movements/Advance
@onready var move_back_button = $AbilityContainer/BaseAbilities/BaseAbilities/Movements/Recede
@onready var defend_button = $AbilityContainer/BaseAbilities/BaseAbilities/Defend
@onready var movements = $AbilityContainer/BaseAbilities/BaseAbilities/Movements
@onready var rounds = $Rounds
@onready var round_counter = $Rounds/RoundCounter
@onready var round_counter_animator = $Rounds/RoundCounter/AnimationPlayer
var fast_round_tween:Tween

func _ready():
	hideUI()
	fast_round_tween = create_tween().set_loops()
	fast_round_tween.stop()
	#fast_round_tween.chain()

func initialize():
	for button in base_abilities.get_children():
		if !button is Button:
			continue
		
		if button.ability != null:
			print('giving ', button.ability)
			giveButtonFunction(button, button.ability)
		elif button.descriptions['title'] == 'escape':
			print('give escape funcs')
	for button in movements.get_children():
		giveButtonFunction(button, button.ability)
	
	CombatGlobals.tension_changed.connect(tension_bar.setValue)

func showAbilities(combatant: ResCombatant):
	for child in ability_buttons.get_children():
		if child is Button:
			child.queue_free()
	
	if !combat_scene.isCombatValid():
		return
	
	if combatant.equipped_weapon != null:
		setButtonDisabled(gear_button,false)
		gear_button.ability = combatant.equipped_weapon.effect
		gear_button.custom_charge = ability_buttons.equipped_weapon.durability
		if !combatant.equipped_weapon.effect.enabled or combatant.equipped_weapon.durability <= 0:
			setButtonDisabled(gear_button,true)
		giveButtonFunction(gear_button,combatant.equipped_weapon.effect,combatant.equipped_weapon)
	else:
		setButtonDisabled(gear_button,true)
		gear_button.descriptions['icon'] = COMBAT_GEAR_ICON
		gear_button.ability_icon.texture = gear_button.descriptions['icon']
	
	for ability in combatant.ability_set: 
		var button = OverworldGlobals.createAbilityButton(ability)
		giveButtonFunction(button,ability)
		ability_buttons.add_child(button)
		ability_buttons.move_child(button,0)
		#await button.tree_entered
	canUseAbility(defend_button)
	
	await get_tree().process_frame
	if getAbilityButtons().size() < 4:
		fillInvalid()
	
	await get_tree().process_frame
	showUI()
	tweenAbilityButtons(getAbilityButtons())
	tweenAbilityButtons(base_abilities.get_children())
	
	var last_used_ability = combat_scene.last_used_ability
	print(last_used_ability)
	if last_used_ability.keys().has(combatant) and combatant.ability_set.has(last_used_ability[combatant][0]):
		print('zoingle')
		for child in getAbilityButtons():
			if child.ability == last_used_ability[combatant][0]: 
				print('pringle')
				child.grab_focus()
	else:
		OverworldGlobals.setMenuFocus(ability_buttons)

func getAbilityButtons():
	return ability_buttons.get_children().filter(func(control): return control is Button)

func giveButtonFunction(button:Button, ability:ResAbility,weapon:ResWeapon=null):
	var active_combatant = combat_scene.active_combatant
	var combatants = combat_scene.combatants
	button.pressed.connect(
		func(): 
			combat_scene.forceCastAbility(ability, weapon)
			hideUI()
			)
	#button.focus_entered.connect(func(): combat_scene.updateDescription(ability))
	#button.mouse_entered.connect(func(): combat_scene.updateDescription(ability))
	if !ability.enabled or !ability.canUse(active_combatant, combatants):
		setButtonDisabled(button,true)

func tweenAbilityButtons(buttons: Array, sound:String='536805__egomassive__gun_2.ogg'):
	for button in buttons:
		button.modulate = Color.TRANSPARENT
	await get_tree().process_frame
	for button in buttons:
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(button, 'scale', Vector2(1.1,1.1), 0.005)
		tween.tween_property(button, 'scale', Vector2(1.0,1.0), 0.05)
		tween.set_parallel(true)
		tween.tween_property(button, 'modulate', Color.WHITE, 0.025)
		if button is Button and button.disabled:
			button.dimButton()
		if button is Button and !button.disabled:
			button.undimButton()
		await tween.finished
		if sound != '':
			OverworldGlobals.playSound(sound,-6.0)
		#await get_tree().create_timer(0.025).timeout

func writeCombatLog(mesesage:String):
	if combat_log_animator.is_playing():
		combat_log_animator.stop()
		combat_log_animator.play('RESET')
	
	combat_log.text = mesesage
	combat_log_animator.play("Show")
	await combat_log_animator.animation_finished
	combat_log_animator.play("Hide")

func hideUI():
	#create_tween().tween_property(self,'modulate',Color.TRANSPARENT,0.25).set_ease(Tween.EASE_OUT)
	ability_buttons.hide()
	escape_button.hide()
	rounds.hide()

func showUI():
	create_tween().tween_property(self,'modulate',Color.WHITE,0.25).set_ease(Tween.EASE_IN)
	hideMovements()
	ability_buttons.show()
	escape_button.show()
	rounds.show()
	tweenAbilityButtons(getAbilityButtons())
	tweenAbilityButtons(base_abilities.get_children(),'')
	#await get_tree().process_frame
	#OverworldGlobals.setMenuFocus(ability_buttons)

func fillInvalid():
	for i in range(4-getAbilityButtons().size()):
		var button: CustomAbilityButton = load("res://scenes/user_interface/AbilityButton.tscn").instantiate()
		button.descriptions['icon'] = EMPTY_ABILITY_ICON
		ability_buttons.add_child(button)
		ability_buttons.move_child(button,(getAbilityButtons().size()-1))
		setButtonDisabled(button,true)


func _on_escape_button_focus_entered():
	showEscapeChance()

func _on_escape_button_focus_exited():
	hideEscapeChance()

func _on_escape_button_mouse_entered():
	showEscapeChance()

func _on_escape_button_mouse_exited():
	hideEscapeChance()

func showEscapeChance():
	escape_chance.text = str(combat_scene.calculateEscapeChance()*100.0)+'%'
	#escape_chance.modulate = Color.YELLOW
	create_tween().tween_property(escape_chance, 'modulate', Color.YELLOW, 0.25).set_ease(Tween.EASE_IN)
	if escape_button.position == escape_button_default_pos:
		create_tween().tween_property(escape_button, 'position', escape_button.position+Vector2(-20,0), 0.2).set_ease(Tween.EASE_IN)
func hideEscapeChance():
	escape_chance.text = str(combat_scene.calculateEscapeChance()*100.0)+'%'
	#escape_chance.modulate = Color.WHITE
	create_tween().tween_property(escape_chance, 'modulate', Color.TRANSPARENT, 0.25).set_ease(Tween.EASE_OUT)
	create_tween().tween_property(escape_button, 'position', escape_button_default_pos, 0.2).set_ease(Tween.EASE_OUT)


func _on_move_pressed():
	setButtonDisabled(move_button,true)
	showMovements()
	
	#await get_tree().process_frame

func showMovements():
	movements.show()
	canUseAbility(move_forward_button)
	canUseAbility(move_back_button)
	tweenAbilityButtons(movements.get_children())
	if !move_forward_button.disabled:
		move_forward_button.grab_focus()
	else:
		move_back_button.grab_focus()

func canUseAbility(button: CustomAbilityButton):
	var active_combatant = combat_scene.active_combatant
	var combatants = combat_scene.combatants
	
	if button.ability.name == 'Defend':
		setButtonDisabled(button, active_combatant.hasStatusEffect('Guard'))
	else:
		setButtonDisabled(button, !(button.ability.enabled and button.ability.canUse(active_combatant, combatants)))

func hideMovements():
	movements.hide()


func _on_pass_pressed():
	combat_scene.confirm.emit()
	hideUI()


func _on_escape_button_pressed():
	combat_scene.attemptEscape()


func _on_advance_focus_exited():
	await get_tree().process_frame
	if !move_back_button.has_focus():
		hideMovements()
		setButtonDisabled(move_button,false)
		move_button._on_focus_exited()

func _on_recede_focus_exited():
	await get_tree().process_frame
	if !move_forward_button.has_focus():
		hideMovements()
		setButtonDisabled(move_button,false)
		move_button._on_focus_exited()
func updateRoundCounter(count:int):
	if !rounds.visible:
		rounds.show()
	round_counter.text = str(count)
	round_counter_animator.play("New_Round")
	if int(round_counter.text) <= 4 and !fast_round_tween.is_running():
		fast_round_tween.tween_property(rounds,'modulate', Color.YELLOW, 0.5)
		fast_round_tween.tween_property(rounds,'modulate', Color.WHITE, 1.5).from(Color.YELLOW)
		fast_round_tween.play()
	elif int(round_counter.text) > 4 and fast_round_tween.is_running():
		fast_round_tween.stop()
		rounds.modulate=Color.WHITE

func setButtonDisabled(button:CustomAbilityButton,set_to:bool):
	button.disabled = set_to
	if button.disabled:
		button.dimButton()
		button.focus_mode = Control.FOCUS_NONE
	else:
		button.undimButton()
		button.focus_mode = Control.FOCUS_ALL
