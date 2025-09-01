extends Control
class_name CombatUI

const COMBAT_GEAR_ICON = preload("res://images/ability_icons/combat_gear.png")
const EMPTY_ABILITY_ICON = preload("res://images/ability_icons/invalid.png")
@export var tension_color:Color = Color.DARK_ORANGE
@onready var ability_buttons = $AbilityContainer
@onready var base_abilities = $AbilityContainer/BaseAbilities/BaseAbilities
@onready var tension_bar: CustomCountBar = $Tension/TensionBar
@onready var tension_whole = $Tension
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
@onready var round_text = $Rounds/RoundText
@onready var round_counter = $Rounds/RoundCounter
@onready var round_counter_animator = $Rounds/RoundCounter/AnimationPlayer
var tension_orig_pos
var rounds_orig_pos

func _ready():
	tension_orig_pos = tension_whole.position
	rounds_orig_pos = rounds.position
	tension_bar.setValue(CombatGlobals.tension)
	hideUI()

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
	
	CombatGlobals.tension_changed.connect(setTensionValue)

func setTensionValue(prev_amount:int,amount:int, target:CombatantScene):
	if prev_amount == amount:
		return
	var tension_increased:bool = prev_amount < amount
	
	setTensionBarVisible(true)
	tension_bar.setValue(amount) # Set value
	await get_tree().process_frame
	if target != null and tension_increased:
		spawnTensionParticles(target, amount-prev_amount, target.combatant_resource is ResPlayerCombatant)
	if tension_increased:
		var circles = tension_bar.getCircles('filled')
		circles.reverse()
		increaseTensionBarAnimation(circles,amount-prev_amount)
	else:
		var circles = tension_bar.getCircles('empty')
		decreaseTensionBarAnimation(circles,prev_amount-amount)
		explodeTensionParticles(combat_scene.active_combatant.combatant_scene,prev_amount-amount)

func increaseTensionBarAnimation(circles,increased_amount:int):
	var increased = 0
	for circle in circles:
		if increased >= increased_amount:
			break
		var orig_pos = circle.position
		var tween = create_tween().chain().set_trans(Tween.TRANS_CUBIC)
		var modulate_tween = create_tween().chain()
		tween.tween_property(circle,'position',circle.position+Vector2(0,-4),0.12).set_ease(Tween.EASE_IN)
		tween.tween_property(circle,'position',orig_pos,0.6).set_ease(Tween.EASE_OUT)
		modulate_tween.tween_property(circle,'modulate',tension_color,0.25)
		modulate_tween.tween_property(circle,'modulate',Color.WHITE,1.0)
		increased += 1
		await get_tree().create_timer(0.1).timeout

func decreaseTensionBarAnimation(circles, decrease_amount:int):
	combat_scene.battleFlash('Flash', tension_color)
	var decreased = 0
	for circle in circles:
		if decreased >= decrease_amount:
			break
		var tween = create_tween().parallel()
		tween.tween_property(circle,'scale',Vector2(2.0,2.0),0.2).set_ease(Tween.EASE_OUT)
		tween.chain()
		tween.tween_property(circle,'scale',Vector2(1.0,1.0),0.1).set_ease(Tween.EASE_OUT)
		tween.tween_property(circle,'modulate',Color.RED,0.1)
		tween.tween_property(circle,'modulate',Color.WHITE,0.2)
		decreased +=1
		await get_tree().create_timer(0.1).timeout

func spawnTensionParticles(target:CombatantScene, tp_amount:int,is_player:bool):
	var pitch = 1.0
	var direction = 1.0
	var receiver = combat_scene.active_combatant.combatant_scene
	if is_player:
		direction = -1.0
		receiver = target
	
	for i in range(tp_amount):
		var tween = create_tween().chain()
		var tp_particle = Sprite2D.new()
		tween.finished.connect(
			func(): 
				var yellow_pulse = create_tween().chain()
				yellow_pulse.tween_property(receiver,'modulate',tension_color,0.1)
				yellow_pulse.tween_property(receiver,'modulate',Color.WHITE,0.5)
				tp_particle.queue_free()
				OverworldGlobals.playSound("res://audio/sounds/27_sword_miss_3.ogg",0.0,pitch,false)
				)
		tp_particle.modulate = tension_color
		tp_particle.texture = load("res://images/sprites/tp_particle.png")
		combat_scene.add_child(tp_particle)
		tp_particle.global_position = target.global_position
		tween.tween_property(
			tp_particle, 
			'global_position', 
			tp_particle.global_position+Vector2(randf_range(32,48)*direction,randf_range(-16,16)*direction),
			0.25
			).set_ease(Tween.EASE_IN)
		tween.tween_property(tp_particle,'rotation', randf_range(-8,8),0.15)
		tween.tween_property(tp_particle,'global_position', receiver.global_position,0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		pitch += 0.2
		await get_tree().create_timer(0.1).timeout

func explodeTensionParticles(target:CombatantScene, tp_amount:int):
	var pitch = 1.0
	for i in range(tp_amount):
		var tween = create_tween().chain()
		var tp_particle = Sprite2D.new()
		tween.finished.connect(
			func(): 
				var modulate_tween = create_tween()
				var pulse = create_tween().chain()
				pulse.tween_property(combat_scene.active_combatant.combatant_scene,'modulate',tension_color,0.1)
				pulse.tween_property(combat_scene.active_combatant.combatant_scene,'modulate',Color.WHITE,0.25)
				modulate_tween.tween_property(tp_particle,'modulate', Color.TRANSPARENT,0.25)
				await modulate_tween.finished
				tp_particle.queue_free()
				)
		tp_particle.modulate = tension_color
		tp_particle.texture = load("res://images/sprites/tp_particle.png")
		combat_scene.add_child(tp_particle)
		tp_particle.global_position = target.global_position
		tween.tween_property(
			tp_particle, 
			'global_position', 
			tp_particle.global_position+Vector2(randf_range(-64,64),randf_range(-32,32)),
			0.12
			).set_ease(Tween.EASE_OUT)
		OverworldGlobals.playSound("res://audio/sounds/07_human_atk_sword_1.ogg",0.0,pitch,false)
		pitch += 0.2
		await get_tree().create_timer(0.08).timeout

func showAbilities(combatant: ResCombatant):
	for child in ability_buttons.get_children():
		if child is Button:
			child.queue_free()
	
	if !combat_scene.isCombatValid():
		return
	
	setButtonDisabled(escape_button, !combat_scene.can_escape)
	if combatant.equipped_weapon != null:
		setButtonDisabled(gear_button,false,false)
		gear_button.ability = combatant.equipped_weapon.effect
		gear_button.custom_charge = ability_buttons.equipped_weapon.durability
		if !combatant.equipped_weapon.effect.enabled or combatant.equipped_weapon.durability <= 0:
			setButtonDisabled(gear_button,true,false)
		giveButtonFunction(gear_button,combatant.equipped_weapon.effect,combatant.equipped_weapon)
	else:
		setButtonDisabled(gear_button,true,false)
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
	if last_used_ability.keys().has(combatant) and combatant.ability_set.has(last_used_ability[combatant][0]):
		for child in getAbilityButtons():
			if child.ability == last_used_ability[combatant][0]: 
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
			if ability.tension_cost > 0:
				setTensionBarVisible(true)
				showTensionCost(ability.tension_cost)
			)
	if !ability.enabled or !ability.canUse(active_combatant, combatants):
		setButtonDisabled(button,true,false)

func tweenAbilityButtons(buttons: Array, sound:String='536805__egomassive__gun_2.ogg'):
	for button in buttons:
		button.modulate = Color.TRANSPARENT
	await get_tree().process_frame
	for button in buttons:
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(button, 'scale', Vector2(1.1,1.1), 0.005).set_ease(Tween.EASE_IN)
		tween.tween_property(button, 'scale', Vector2(1.0,1.0), 0.05).set_ease(Tween.EASE_OUT)
		tween.set_parallel(true)
		tween.tween_property(button, 'modulate', Color.WHITE, 0.25).set_ease(Tween.EASE_OUT)
		if button is Button and button.disabled:
			button.dimButton()
		if button is Button and !button.disabled:
			button.undimButton()
		await get_tree().create_timer(0.05).timeout
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
	setRoundsVisible(false)
	setTensionBarVisible(false)


func showUI(set_focus:bool=false):
	create_tween().tween_property(self,'modulate',Color.WHITE,0.25).set_ease(Tween.EASE_IN)
	hideMovements()
	ability_buttons.show()
	escape_button.show()
	setRoundsVisible(true)
	setTensionBarVisible(true)
	tweenAbilityButtons(getAbilityButtons())
	tweenAbilityButtons(base_abilities.get_children(),'')
	if set_focus:
		OverworldGlobals.setMenuFocus(ability_buttons)
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
		setButtonDisabled(button, active_combatant.hasStatusEffect('Guard'),false)
	else:
		setButtonDisabled(button, !(button.ability.enabled and button.ability.canUse(active_combatant, combatants)),false)

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
	setRoundsVisible(true)
	round_counter.text = str(count)
	if int(round_counter.text) <= 4:
		print('zipple')
		round_text.text = '[wave]Round'
	else:
		round_text.text = 'Round'
	round_counter_animator.play("New_Round")

func setButtonDisabled(button:CustomAbilityButton,set_to:bool, set_focus=true):
	button.disabled = set_to
	if button.disabled:
		button.dimButton()
		if set_focus: button.focus_mode = Control.FOCUS_NONE
	else:
		button.undimButton()
		if set_focus: button.focus_mode = Control.FOCUS_ALL

func setTensionBarVisible(set_to:bool):
	var tween = create_tween().set_parallel()
	resetTensionColors()
	if set_to:
		tween.tween_property(tension_whole,'position',tension_orig_pos,0.25)
		tween.tween_property(tension_whole,'modulate',Color.WHITE,0.25)
	else:
		tween.tween_property(tension_whole,'position',tension_orig_pos+Vector2(0,8),0.25)
		tween.tween_property(tension_whole,'modulate',Color.TRANSPARENT,0.25)

func showTensionCost(cost:int):
	var i = 0
	var circles = tension_bar.getCircles('filled')
	circles.reverse()
	for circle in circles:
		if i >= cost:
			return
		circle.modulate = Color.RED
		i += 1

func resetTensionColors():
	for circle in tension_bar.getCircles():
		circle.modulate = Color.WHITE

func setRoundsVisible(set_to:bool):
	var tween = create_tween().set_parallel()
	if set_to:
		tween.tween_property(rounds,'position',rounds_orig_pos,0.25)
		tween.tween_property(rounds,'modulate',Color.WHITE,0.25)
	else:
		tween.tween_property(rounds,'position',rounds_orig_pos+Vector2(0,-8),0.25)
		tween.tween_property(rounds,'modulate',Color.TRANSPARENT,0.25)
