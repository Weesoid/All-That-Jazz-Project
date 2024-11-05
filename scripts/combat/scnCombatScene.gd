extends Node2D
class_name CombatScene

@export var COMBATANTS: Array[ResCombatant]

@onready var combat_camera: DynamicCamera = $CombatCamera
@onready var combat_log = $CombatCamera/Interface/LogContainer
@onready var team_container_markers = $TeamContainer.get_children()
@onready var enemy_container_markers = $EnemyContainer.get_children()
@onready var onslaught_container = $OnslaughtContainer
@onready var onslaught_container_animator = $OnslaughtContainer/AnimationPlayer
@onready var secondary_panel = $CombatCamera/Interface/SecondaryPanel
@onready var secondary_action_panel = $CombatCamera/Interface/SecondaryPanel/OptionContainer
@onready var secondary_panel_container = $CombatCamera/Interface/SecondaryPanel/OptionContainer/Scroller/Container
@onready var secondary_description = $CombatCamera/Interface/SecondaryPanel/DescriptionPanel/MarginContainer/RichTextLabel
@onready var action_panel = $CombatCamera/Interface/ActionPanel/ActionPanel/MarginContainer/Buttons
@onready var whole_action_panel = $CombatCamera/Interface/ActionPanel
@onready var escape_button = $CombatCamera/Interface/ActionPanel/ActionPanel/MarginContainer/Buttons/Escape
@onready var ui_inspect_target = $CombatCamera/Interface/Inspect
@onready var ui_attribute_view = $CombatCamera/Interface/Inspect/AttributeView
@onready var ui_status_inspect = $CombatCamera/Interface/Inspect/PanelContainer/StatusEffects
@onready var ui_status_inspect_container = $CombatCamera/Interface/Inspect/PanelContainer
@onready var round_counter = $CombatCamera/Interface/ProgressBar/Counts/RoundCounter
@onready var turn_counter = $CombatCamera/Interface/ProgressBar/Counts/TurnCounter
@onready var transition_scene = $CombatCamera/BattleTransition
@onready var transition = $CombatCamera/BattleTransition.get_node('AnimationPlayer')
@onready var battle_music = $BattleMusic
@onready var battle_sounds = $BattleSounds
@onready var battle_back = $CombatCamera/DefaultBattleParallax.get_node('AnimationPlayer')
@onready var top_log_label = $CombatCamera/Interface/TopLog
@onready var top_log_animator = $CombatCamera/Interface/TopLog/AnimationPlayer
@onready var ui_animator = $CombatCamera/Interface/InterfaceAnimator
@onready var guard_button = $CombatCamera/Interface/ActionPanel/ActionPanel/MarginContainer/Buttons/Guard
@onready var skills_button = $CombatCamera/Interface/ActionPanel/ActionPanel/MarginContainer/Buttons/Skills
@onready var tension_bar = $CombatCamera/Interface/ProgressBar
@onready var escape_chance_label = $CombatCamera/Interface/ActionPanel/ActionPanel/MarginContainer/Buttons/Escape/Label
@onready var team_hp_bar = $OnslaughtContainer/ProgressBar

var combatant_turn_order: Array
var combat_dialogue: CombatDialogue
var unique_id: String
var target_state = 0 # 0=None, 1=Single, 2=Multi
var active_combatant: ResCombatant
var valid_targets
var target_combatant
var target_index = 0
var combat_event: ResCombatEvent
var selected_ability: ResAbility
var run_once = true
var drops = {}
var total_experience = 0
var turn_count = 0
var round_count = 0
var player_turn_count = 0
var enemy_turn_count = 0
var battle_music_path: String = ""
var combat_result: int = -1
var dogpile_count: int = 0
var camera_position: Vector2 = Vector2(0, 0)
var enemy_reinforcements: Array[ResCombatant]
var tamed_combatants: Array[ResCombatant]
var bonus_escape_chance = 0.0
var onslaught_mode = false
var onslaught_combatant: ResPlayerCombatant
var previous_position: Vector2
var tween_running

signal confirm
signal target_selected
signal update_exp(value: float, max_value: float)
signal dialogue_done
signal combat_done

#********************************************************************************
# INITIALIZATION AND COMBAT LOOP
#********************************************************************************
func _ready():
	team_hp_bar.process_mode = Node.PROCESS_MODE_DISABLED
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if OverworldGlobals.getCurrentMap().has_node('Balloon'):
		OverworldGlobals.getCurrentMap().get_node('Balloon').queue_free()
	
	transition_scene.visible = true
	CombatGlobals.execute_ability.connect(commandExecuteAbility)
	renameDuplicates()
	
	for combatant in COMBATANTS:
		addCombatant(combatant)
		if combatant is ResEnemyCombatant:
			combatant.STAT_VALUES['hustle'] += 2 * (dogpile_count+1)
	
	if battle_music_path != "" and SettingsGlobals.toggle_music:
		battle_music.stream = load(battle_music_path)
		battle_music.play()
	
	transition.play('Out')
	await transition.animation_finished
	
	for combatant in COMBATANTS:
		tickStatusEffects(combatant)
	await removeDeadCombatants(false)
	
	rollTurns()
	setActiveCombatant(false)
	while active_combatant.STAT_VALUES['hustle'] < 0:
		setActiveCombatant(false)
	
	for button in action_panel.get_children():
		button.focus_entered.connect(func(): secondary_panel.hide())
	battle_back.play('Show')
	active_combatant.act()
	
	if combat_dialogue != null:
		combat_dialogue.initialize()
	
	transition_scene.visible = false
	
	if dogpile_count > 0:
		writeTopLogMessage('Dogpile! (x%s)' % dogpile_count)
	
func _process(_delta):
	turn_counter.text = str(turn_count)
	round_counter.text = str(round_count)
	match target_state:
		1: playerSelectSingleTarget()
		2: playerSelectMultiTarget()
		3: playerSelectInspection()

func _unhandled_input(_event):
	if onslaught_mode and Input.is_action_just_pressed('ui_left') and !tween_running and onslaught_combatant != null and !onslaught_combatant.isDead():
		moveOnslaught(-1)
	if onslaught_mode and Input.is_action_just_pressed('ui_right') and !tween_running and onslaught_combatant != null and !onslaught_combatant.isDead():
		moveOnslaught(1)
	
	if (Input.is_action_just_pressed('ui_cancel') or Input.is_action_just_pressed("ui_show_menu")  or Input.is_action_just_pressed("ui_right_mouse")) and secondary_action_panel.visible and !onslaught_mode: 
		resetActionLog()
	if Input.is_action_just_pressed('ui_home'):
		if action_panel.visible == true:
			toggleUI(false)
		else:
			toggleUI(true)

func on_player_turn():
	CombatGlobals.active_combatant_changed.emit(active_combatant)
	whole_action_panel.show()
	if has_node('QTE'):
		await CombatGlobals.qte_finished
		await get_node('QTE').tree_exited
	
	Input.action_release("ui_accept")
	
	resetActionLog()
	skills_button.disabled = active_combatant.ABILITY_SET.is_empty() and !active_combatant.hasEquippedWeapon()
	action_panel.show()
	action_panel.get_child(0).grab_focus()
	ui_animator.play('ShowActionPanel')
	await confirm
	end_turn()

func on_enemy_turn():
	CombatGlobals.active_combatant_changed.emit(active_combatant)
	whole_action_panel.hide()
	ui_animator.play_backwards('ShowActionPanel')
	if has_node('QTE'): await CombatGlobals.qte_finished
	if await checkWin(): return
	
	selected_ability = active_combatant.AI_PACKAGE.selectAbility(active_combatant.ABILITY_SET, active_combatant)
	if selected_ability != null:
		valid_targets = selected_ability.getValidTargets(sortCombatantsByPosition(), false)
		if selected_ability.getTargetType() == 1 and selected_ability.TARGET_GROUP != 2:
			target_combatant = active_combatant.AI_PACKAGE.selectTarget(valid_targets)
		else:
			target_combatant = valid_targets
		if target_combatant != null:
			executeAbility()
	else:
		selected_ability = load("res://resources/combat/abilities/Struggle.tres")
		valid_targets = selected_ability.getValidTargets(sortCombatantsByPosition(), false)
		target_combatant = active_combatant.AI_PACKAGE.selectTarget(valid_targets)
		if target_combatant != null:
			executeAbility()
	#var timer = Timer.new()
	#timer.timeout.connect(func(): confirm.emit())
	#add_child(timer)
	#timer.start(10.0)
	await confirm
	#timer.queue_free() TIME FAIL SAFE
	end_turn()

func end_turn(combatant_act=true):
	for combatant in COMBATANTS:
		if combatant.isDead(): continue
		CombatGlobals.dialogue_signal.emit(combatant)
	
	#moveamera(camera_position, 0.15)
	if combatant_act:
		active_combatant.TURN_CHARGES -= 1
		combatant_turn_order.remove_at(0)
		if active_combatant.TURN_CHARGES <= 0:
			active_combatant.ACTED = true
	
	if allCombatantsActed():
		rollTurns()
		end_turn(false)
		return
	
	turn_count += 1
	if active_combatant is ResPlayerCombatant:
		player_turn_count += 1
	else:
		enemy_turn_count += 1
	
	if combat_event != null and turn_count % combat_event.TURN_TRIGGER == 0:
		ui_animator.play_backwards('ShowActionPanel')
		combat_log.writeCombatLog(combat_event.EVENT_MESSAGE)
		commandExecuteAbility(null, combat_event.ABILITY)
		await get_tree().create_timer(2.0).timeout
		if await checkWin(): return
	elif combat_event != null and turn_count % combat_event.TURN_TRIGGER == combat_event.TURN_TRIGGER - 3:
		combat_log.writeCombatLog(combat_event.WARNING_MESSAGE)
	
	var turn_title = 'turn/%s' % turn_count
	CombatGlobals.dialogue_signal.emit(turn_title)
	
	for combatant in COMBATANTS:
		if combatant.isDead(): 
			continue
		refreshInstantCasts(combatant)
		tickStatusEffects(combatant, true)
		CombatGlobals.dialogue_signal.emit(combatant)
	removeDeadCombatants()
	
	# Reset values
	run_once = true
	target_index = 0
	secondary_panel.hide()
	
	# REINFORCEMENTS
	randomize()
	if turn_count % 99 == 0 and getDeadCombatants('enemies').size() > 0 and isCombatValid():
		combat_log.writeCombatLog('Enemy reinforcements are incoming!')
	if turn_count % 100 == 0 and getDeadCombatants('enemies').size() > 0 and isCombatValid():
		combat_log.writeCombatLog('Enemy reinforcements arrived!')
		bonus_escape_chance -= 0.5
		var replace = []
		for combatant in COMBATANTS:
			if combatant.isDead(): replace.append(combatant)
		for combatant in replace:
			var replacement: ResEnemyCombatant = enemy_reinforcements.pick_random().duplicate()
			replacement.DROP_POOL = {}
			await replaceCombatant(combatant, replacement, "res://scenes/animations/Reinforcements.tscn")
	
	# Determine next combatant
	if selected_ability == null or !selected_ability.INSTANT_CAST:
		if has_node('QTE'):
			await CombatGlobals.qte_finished
			await get_node('QTE').tree_exited
		setActiveCombatant()
	else:
		selected_ability.ENABLED = false
		active_combatant.TURN_CHARGES += 1
		combatant_turn_order.push_front([active_combatant, 1])
	
	if checkDialogue():
		await DialogueManager.dialogue_ended
	
	if active_combatant.STAT_VALUES['hustle'] >= 0:
		active_combatant.act()
	else:
		end_turn()
		return
	if await checkWin(): return

func setActiveCombatant(tick_effect=true):
	active_combatant = combatant_turn_order[0][0]
	if tick_effect:
		tickStatusEffects(active_combatant)
		removeDeadCombatants()

func removeDeadCombatants(fading=true, is_valid_check=true):
	if !isCombatValid() and is_valid_check: return
	
	for combatant in getDeadCombatants():
		if combatant is ResEnemyCombatant:
			if !combatant.getStatusEffectNames().has('Knock Out'): 
				clearStatusEffects(combatant)
				CombatGlobals.addStatusEffect(combatant, 'KnockOut', true)
				combatant.ACTED = true
				total_experience += combatant.getExperience()
			if combatant.SPAWN_ON_DEATH != null:
				replaceCombatant(combatant, combatant.SPAWN_ON_DEATH)
		elif combatant is ResPlayerCombatant:
			if !combatant.hasStatusEffect('Fading') and !combatant.hasStatusEffect('Knock Out') and fading: 
				clearStatusEffects(combatant)
				CombatGlobals.addStatusEffect(combatant, 'Fading', true)
			elif !combatant.getStatusEffectNames().has('Knock Out') and !fading:
				CombatGlobals.addStatusEffect(combatant, 'KnockOut', true)
				combatant.ACTED = true
			if !fading:
				await get_tree().create_timer(0.25).timeout
#********************************************************************************
# BASE SCENE NODE CONTROL
#********************************************************************************
func _on_skills_pressed():
	getPlayerAbilities(active_combatant.ABILITY_SET)
	if secondary_panel_container.get_child_count() == 0: return
	animateSecondaryPanel('show')
	secondary_panel_container.get_child(0).grab_focus()

func _on_guard_pressed():
	resetActionLog()
	animateSecondaryPanel('show')
	Input.action_release("ui_accept")
	forceCastAbility(active_combatant.ABILITY_SLOT)

func _on_inspect_pressed():
	ui_animator.play('ShowInspect')
	target_state = 3

func _on_escape_pressed():
	if CombatGlobals.randomRoll(calculateEscapeChance()):
		CombatGlobals.combat_lost.emit(unique_id)
		concludeCombat(2)
	else:
		for combatant in getCombatantGroup('team'):
			CombatGlobals.addStatusEffect(combatant, 'Dazed', true, true)
		bonus_escape_chance += 0.1
		confirm.emit()

func _on_escape_focus_entered():
	escape_chance_label.text = str(calculateEscapeChance()*100.0)+'%'
	escape_chance_label.show()

func _on_escape_mouse_entered():
	escape_chance_label.text = str(calculateEscapeChance()*100.0)+'%'
	escape_chance_label.show()

func _on_escape_mouse_exited():
	escape_chance_label.hide()

func _on_escape_focus_exited():
	escape_chance_label.hide()

func calculateEscapeChance()-> float:
	var hustle_enemies = 0
	var hustle_allies = 0
	for combatant in getCombatantGroup('enemies'):
		hustle_enemies += combatant.BASE_STAT_VALUES['hustle']
	for combatant in getCombatantGroup('team'):
		hustle_allies += combatant.BASE_STAT_VALUES['hustle']
	return snappedf((0.5 + ((hustle_allies-hustle_enemies)*0.15)) + bonus_escape_chance, 0.01)

func toggleUI(visibility: bool):
	for marker in enemy_container_markers:
		if marker.get_child_count() != 0:
			marker.get_child(0).get_node('CombatBars').visible = visibility
	for marker in team_container_markers:
		if marker.get_child_count() != 0:
			marker.get_child(0).get_node('CombatBars').visible = visibility
	
	for child in combat_camera.get_children():
		if child is Control:
			child.visible = visibility
	if visibility: resetActionLog()

#********************************************************************************
# ABILITY SELECTION, TARGETING, AND EXECUTION
#********************************************************************************
func getPlayerAbilities(ability_set: Array[ResAbility]):
	for child in secondary_panel_container.get_children():
		child.queue_free()
	
	if active_combatant.EQUIPPED_WEAPON != null:
		var button = OverworldGlobals.createCustomButton()
		var weapon: ResWeapon = active_combatant.EQUIPPED_WEAPON
		button.text = weapon.EFFECT.NAME + ' (%s/%s)' % [weapon.durability, weapon.max_durability]
		button.pressed.connect(func(): forceCastAbility(weapon.EFFECT, weapon))
		button.focus_entered.connect(func():updateDescription(weapon.EFFECT))
		button.expand_icon = true
		button.icon = weapon.ICON
		if !weapon.EFFECT.ENABLED or weapon.durability <= 0:
			button.disabled = true
		secondary_panel_container.add_child(button)
	for ability in ability_set:
		secondary_panel_container.add_child(createAbilityButton(ability))
	
	await get_tree().process_frame
	OverworldGlobals.setMenuFocus(secondary_panel_container)

func getMoveAbilities():
	for child in secondary_panel_container.get_children():
		child.free()
	
	var pass_button = OverworldGlobals.createCustomButton()
	pass_button.text = 'Pass'
	pass_button.pressed.connect(func(): confirm.emit())
	pass_button.focus_entered.connect(func():updateDescription(null, 'Pass this turn.'))
	secondary_panel_container.add_child(createAbilityButton(load("res://resources/combat/abilities/Advance.tres")))
	secondary_panel_container.add_child(createAbilityButton(load("res://resources/combat/abilities/Recede.tres")))
	secondary_panel_container.add_child(pass_button)
	
	animateSecondaryPanel('show')
	secondary_panel_container.get_child(0).grab_focus()

func createAbilityButton(ability: ResAbility)-> Button:
	var button = OverworldGlobals.createCustomButton()
	button.text = ability.NAME
	button.pressed.connect(func(): forceCastAbility(ability))
	button.focus_entered.connect(func():updateDescription(ability))
	button.mouse_entered.connect(func():updateDescription(ability))
	if !ability.ENABLED or !ability.canUse(active_combatant, COMBATANTS):
		button.disabled = true
	return button

func playerSelectSingleTarget():
	if getCombatantGroup('enemies').is_empty() or (valid_targets is Array and valid_targets.is_empty()):
		return
	
	if valid_targets is Array:
		target_combatant = valid_targets[target_index]
	else:
		target_combatant = valid_targets
	moveCamera(target_combatant.SCENE.global_position)
	browseTargetsInputs()
	confirmCancelInputs()

func playerSelectMultiTarget():
	if getCombatantGroup('enemies').is_empty():
		return
	
	target_combatant = selected_ability.getValidTargets(COMBATANTS, true)
	confirmCancelInputs()

func playerSelectInspection():
	action_panel.hide()
	valid_targets = sortCombatantsByPosition()
	target_combatant = valid_targets[target_index]
	ui_inspect_target.show()
	ui_attribute_view.combatant = target_combatant
	
	moveCamera(target_combatant.SCENE.global_position)
	getStatusEffectInfo(target_combatant)
	browseTargetsInputs()
	confirmCancelInputs()

func getStatusEffectInfo(combatant: ResCombatant):
	ui_status_inspect.text = ''
	if combatant.STATUS_EFFECTS.is_empty():
		ui_status_inspect_container.hide()
		return
	
	ui_status_inspect_container.show()
	for effect in combatant.STATUS_EFFECTS:
		ui_status_inspect.text += OverworldGlobals.insertTextureCode(effect.TEXTURE) + effect.DESCRIPTION+'\n'

func executeAbility():
	active_combatant.SCENE.z_index = 100
	for combatant in COMBATANTS:
		if target_combatant is ResCombatant and ((target_combatant != combatant and active_combatant != combatant) or (target_combatant is Array and !target_combatant.has(combatant) and active_combatant != combatant)):
			CombatGlobals.setCombatantVisibility(combatant.SCENE, false)
	if target_combatant is ResPlayerCombatant and target_combatant.SCENE.blocking and active_combatant is ResEnemyCombatant:
		target_combatant.SCENE.allow_block = true
		CombatGlobals.showWarning(target_combatant.SCENE)
	if active_combatant is ResPlayerCombatant:
		CombatGlobals.TENSION -= selected_ability.TENSION_COST
	moveCamera(camera_position)
	
	await get_tree().create_timer(0.25).timeout
	if target_combatant is ResCombatant:
		selected_ability.ABILITY_SCRIPT.animate(active_combatant.SCENE, target_combatant.SCENE, selected_ability)
	else:
		selected_ability.ABILITY_SCRIPT.animate(active_combatant.SCENE, target_combatant, selected_ability)
	CombatGlobals.ability_casted.emit(selected_ability)
	await CombatGlobals.ability_finished
	if has_node('QTE'):
		await CombatGlobals.qte_finished
		await get_node('QTE').tree_exited
	Input.action_release("ui_accept")
	
	for combatant in COMBATANTS:
		CombatGlobals.setCombatantVisibility(combatant.SCENE, true)
	var ability_title = 'ability/%s' % selected_ability.resource_path.get_file().trim_suffix('.tres')
	CombatGlobals.dialogue_signal.emit(ability_title)
	if checkDialogue():
		await DialogueManager.dialogue_ended
	if target_combatant is ResPlayerCombatant and target_combatant.SCENE.blocking and active_combatant is ResEnemyCombatant:
		target_combatant.SCENE.allow_block = false
	
	confirm.emit()

func skipTurn():
	target_state = 0
	if run_once:
		Input.action_release("ui_accept")
		confirm.emit()
		action_panel.hide()
		run_once = false

func commandExecuteAbility(target, ability: ResAbility):
	if ability.TARGET_TYPE == ability.TargetType.MULTI:
		target = ability.getValidTargets(COMBATANTS, active_combatant is ResPlayerCombatant)
	ability.ABILITY_SCRIPT.applyEffects(
						null, 
						target, 
						ability.ANIMATION
						)
#********************************************************************************
# MISCELLANEOUS
#********************************************************************************
func moveCamera(target: Vector2, speed=0.25):
	var tween = create_tween()
	tween.tween_property(combat_camera, 'global_position', target, speed)
	await tween.finished

func zoomCamera(zoom: Vector2, speed=0.25):
	var tween = create_tween()
	tween.tween_property(combat_camera, 'zoom', combat_camera.zoom+zoom, speed)
	await tween.finished

func addCombatant(combatant:ResCombatant, spawned:bool=false):
	if !isCombatValid(): #getCombatantGroup('enemies').size() == 4: 
		return
	var team_container
	combatant.initializeCombatant()
	combatant.player_turn.connect(on_player_turn)
	combatant.enemy_turn.connect(on_enemy_turn)
	if combatant is ResPlayerCombatant:
		team_container = team_container_markers
	else:
		team_container = enemy_container_markers
	for marker in team_container:
		if marker.get_child_count() != 0: continue
		marker.add_child(combatant.SCENE)
		break
	if combatant is ResPlayerCombatant and combatant.isDead():
		combatant.getAnimator().play('Fading')
	else:
		combatant.getAnimator().play('Idle')
	var combat_bars = preload("res://scenes/user_interface/CombatBars.tscn").instantiate()
	combat_bars.attached_combatant = combatant
	combatant.SCENE.add_child(combat_bars)
	if combatant is ResEnemyCombatant and combatant.is_converted:
		combatant.SCENE.rotation_degrees = -180
		combatant.SCENE.get_node('Sprite2D').flip_v = true
		combatant.SCENE.get_node('AnimationPlayer').get_animation('Idle').track_set_key_value(1, 1, Vector2(0, 1))
		combat_bars.rotation_degrees = 180
	if spawned:
		COMBATANTS.append(combatant)
		combatant.ACTED = false
		combatant.TURN_CHARGES = combatant.MAX_TURN_CHARGES
		for turn_charge in range(combatant.MAX_TURN_CHARGES):
			var rolled_speed = randi_range(1, 8) + combatant.STAT_VALUES['hustle']
			combatant_turn_order.append([combatant, rolled_speed])

func replaceCombatant(combatant: ResCombatant, new_combatant: ResCombatant, animation_path:String=''):
	COMBATANTS.erase(combatant)
	combatant_turn_order.erase(combatant)
	await get_tree().create_timer(0.25).timeout
	combatant.SCENE.queue_free()
	await combatant.SCENE.tree_exited
	addCombatant(new_combatant, true)
	if animation_path != '':
		await CombatGlobals.playAbilityAnimation(new_combatant, load(animation_path), 0.15)

func removeCombatant(combatant: ResCombatant):
	COMBATANTS.erase(combatant)
	combatant_turn_order.erase(combatant)
	combatant.SCENE.queue_free()

func forceCastAbility(ability: ResAbility, weapon: ResWeapon=null):
	selected_ability = ability
	valid_targets = selected_ability.getValidTargets(sortCombatantsByPosition(), true)
	print(valid_targets)
	if ability.TARGET_TYPE == ability.TargetType.MULTI:
		addTargetClickButton(active_combatant)
	elif valid_targets is Array:
		for target in valid_targets: addTargetClickButton(target)
	else:
		addTargetClickButton(valid_targets)
	target_state = selected_ability.getTargetType()
	updateDescription(ability)
	ui_animator.play('FocusDescription')
	secondary_action_panel.hide()
	action_panel.hide()
	await target_selected
	runAbility()
	if weapon != null: weapon.useDurability()

func updateDescription(ability: ResAbility, text: String=''):
	if ability != null:
		secondary_description.text = ability.getRichDescription()
	elif text != '':
		secondary_description.text = text
	
	secondary_description.show()

func animateSecondaryPanel(animation: String):
	ui_animator.play('RESET')
	if animation == 'show':
		secondary_action_panel.show()
		secondary_panel.show()
		whole_action_panel.hide()
		ui_animator.play("ShowSecondaryPanel")
	elif animation == 'hide':
		ui_animator.play_backwards("ShowDescriptionPanel")
		ui_animator.play_backwards("ShowOptionPanel")

func getDeadCombatants(type: String=''):
	var combatants = COMBATANTS.duplicate()
	if type == 'enemies':
		combatants = combatants.filter(func(combatant): return combatant is ResEnemyCombatant)
	elif type == 'team':
		combatants = combatants.filter(func(combatant): return combatant is ResPlayerCombatant)
	return combatants.filter(func getDead(combatant): return combatant.isDead())

func addDrop(loot_drops: Dictionary): # DO NOT ADD IMMEDIATELY
	for loot in loot_drops.keys():
		if OverworldGlobals.getCurrentMap().REWARD_BANK['loot'].keys().has(loot):
			OverworldGlobals.getCurrentMap().REWARD_BANK['loot'][loot] += loot_drops[loot]
		else:
			OverworldGlobals.getCurrentMap().REWARD_BANK['loot'][loot] = loot_drops[loot]

func rollTurns():
	OverworldGlobals.playSound("714571__matrixxx__reverse-time.ogg")
	combatant_turn_order.clear()
	for combatant in COMBATANTS:
		if combatant.isDead() and !combatant.hasStatusEffect('Fading'): continue
		randomize()
		combatant.ACTED = false
		combatant.TURN_CHARGES = combatant.MAX_TURN_CHARGES
		for turn_charge in range(combatant.MAX_TURN_CHARGES):
			var rolled_speed = randi_range(1, 8) + combatant.STAT_VALUES['hustle']
			combatant_turn_order.append([combatant, rolled_speed])
	combatant_turn_order.sort_custom(func(a, b): return a[1] > b[1])
	round_count += 1

func allCombatantsActed() -> bool:
	for combatant in COMBATANTS:
		if !combatant.ACTED: return false
	return true

func getCombatantFromTurnOrder(combatant: ResCombatant)-> ResCombatant:
	for data in combatant_turn_order:
		if data[0] == combatant: return combatant
	
	return null

## 'team' or 'enemies'
func getCombatantGroup(type: String)-> Array[ResCombatant]:
	match type:
		'team': return COMBATANTS.duplicate().filter(func getTeam(combatant): return combatant is ResPlayerCombatant)
		'enemies': return COMBATANTS.duplicate().filter(func getEnemies(combatant): return combatant is ResEnemyCombatant)
	
	return [null]

func isCombatantGroupDead(type: String):
	var group = getCombatantGroup(type)
	for combatant in group:
		if !combatant.isDead():
			return false
	
	return true

func isCombatValid()-> bool:
	return !isCombatantGroupDead('team') and !isCombatantGroupDead('enemies')

func getLivingCombatants():
	return COMBATANTS.duplicate().filter(func(combatant: ResCombatant): return !combatant.isDead())

func renameDuplicates():
	var seen = []
	for combatant in COMBATANTS:
		if seen.has(combatant.NAME):
			combatant.NAME = '%s%s' % [combatant.NAME, seen.count(combatant.NAME)]
		else:
			seen.append(combatant.NAME)

func checkWin():
	if isCombatantGroupDead('team'):
		if unique_id != null:
			CombatGlobals.combat_lost.emit(unique_id)
			CombatGlobals.dialogue_signal.emit('lose')
		if checkDialogue():
			await DialogueManager.dialogue_ended
		concludeCombat(0)
		return true
	if isCombatantGroupDead('enemies'):
		if unique_id != null:
			CombatGlobals.combat_won.emit(unique_id)
			CombatGlobals.dialogue_signal.emit('win')
		if checkDialogue():
			await DialogueManager.dialogue_ended
		concludeCombat(1)
		return true
	
	return false

func checkDialogue():
	if combat_dialogue == null:
		return false
	
	return combat_dialogue.dialogue_triggered

func clearStatusEffects(combatant: ResCombatant, ignore_faded:bool=true):
	if ignore_faded:
		var effects = combatant.STATUS_EFFECTS.filter(func(effect: ResStatusEffect):return !effect.NAME.contains('Faded'))
		while !effects.is_empty():
			effects[0].removeStatusEffect()
			effects.remove_at(0)
	else:
		while !combatant.STATUS_EFFECTS.is_empty():
			combatant.STATUS_EFFECTS[0].removeStatusEffect()

func tickStatusEffects(combatant: ResCombatant, per_turn = false):
	for effect in combatant.STATUS_EFFECTS:
		if (per_turn and !effect.TICK_PER_TURN) or (!per_turn and effect.TICK_PER_TURN): 
			continue
		effect.tick()

func refreshInstantCasts(combatant: ResCombatant):
	for ability in combatant.ABILITY_SET:
		if !ability.ENABLED and ability.INSTANT_CAST: ability.ENABLED = true

func incrementIndex(index:int, increment: int, limit: int):
	return (index + increment) % limit

func browseTargetsInputs():
	if !valid_targets is Array:
		return
	
	if Input.is_action_just_pressed("ui_right"):
		OverworldGlobals.playSound("342694__spacejoe__lock-2-remove-key-2.ogg")
		target_index = incrementIndex(target_index, 1, valid_targets.size())
	if Input.is_action_just_pressed("ui_left"):
		OverworldGlobals.playSound("342694__spacejoe__lock-2-remove-key-2.ogg")
		target_index = incrementIndex(target_index, -1, valid_targets.size())

func confirmCancelInputs():
	if Input.is_action_just_pressed("ui_accept") and target_state != 3:
		removeTargetButtons()
		OverworldGlobals.playSound("56243__qk__latch_01.ogg")
		target_selected.emit()
	if Input.is_action_just_pressed("ui_tab") or Input.is_action_just_pressed("ui_right_mouse"):
		removeTargetButtons()
		ui_animator.play_backwards('FocusDescription')
		resetActionLog()
	
func resetActionLog():
	moveCamera(camera_position)
	whole_action_panel.show()
	#combat_camera.zoom = Vector2(1.0, 1.0)
	ui_inspect_target.hide()
	secondary_panel.hide()
	target_state = 0
	target_index = 0
	action_panel.get_child(0).grab_focus()
	action_panel.show()
	ui_animator.play('ShowActionPanel')
	guard_button.disabled = active_combatant is ResPlayerCombatant and (active_combatant.hasStatusEffect('Guard Break') or active_combatant.hasStatusEffect('Guard'))

func runAbility():
	target_state = 0
	if run_once:
		executeAbility()
		action_panel.hide()
		run_once = false

func writeTopLogMessage(message: String):
	top_log_label.text = message
	top_log_animator.stop()
	top_log_animator.play("Show")

func concludeCombat(results: int):
	if combat_result != -1: return
	
	removeDeadCombatants(true, false)
	combat_result = results
	battle_music.stop()
	for combatant in COMBATANTS:
		refreshInstantCasts(combatant)
		clearStatusEffects(combatant, false)
	whole_action_panel.hide()
	secondary_panel.hide()
	target_state = 0
	target_index = 0
	var morale_bonus = 1
	var loot_bonus = 1
	var all_bonuses = ''
	
	if results == 1:
		if turn_count <= 6:
			all_bonuses += '[color=orange]FAST BATTLE![/color] +25% Morale & Increased Drops\n'
			morale_bonus += 1
			loot_bonus += 1
		if enemy_turn_count == 0:
			all_bonuses += '[color=orange]RUTHLESS FINISH![/color] Increased Drops\n'
			loot_bonus += 1
		if round_count == 1:
			all_bonuses += '[color=orange]STRAGETIC VICTORY![/color] +25% Morale\n'
			morale_bonus += 1
		OverworldGlobals.getCurrentMap().REWARD_BANK['experience'] += total_experience * (morale_bonus * 0.25)
		for i in range(loot_bonus):
			for enemy in getCombatantGroup('enemies'): 
				addDrop(enemy.getDrops())
#	else:
#		experience_earnt = -(PlayerGlobals.getRequiredExp()*0.2)
	
	var bc_ui = preload("res://scenes/user_interface/CombatResultScreen.tscn").instantiate()
	for item in drops.keys():
		InventoryGlobals.addItemResource(item, drops[item])
	add_child(bc_ui)
	if results == 1:
		bc_ui.title.text = 'Foes Neutralized!'
	else:
		bc_ui.title.text = 'Escaped!'
	bc_ui.setBonuses(all_bonuses)
#	CombatGlobals.emit_exp_updated(experience_earnt, PlayerGlobals.getRequiredExp())
#	PlayerGlobals.addExperience(experience_earnt)
#	bc_ui.writeDrops(drops)
	
	await bc_ui.done
	bc_ui.queue_free()
	
	transition_scene.visible = true
	transition.play('In')
	await transition.animation_finished
	
	combat_done.emit()
	
	var end_sentence = 'You perished.'
	if combat_dialogue != null: 
		combat_dialogue.disconnectSignal()
		end_sentence = combat_dialogue.end_sentence
	if results == 0:
		OverworldGlobals.showGameOver(end_sentence)
	else:
		OverworldGlobals.addPatrollerPulse(OverworldGlobals.getPlayer(), 80.0, 3)
	CombatGlobals.TENSION = 0
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
	queue_free()

func changeCombatantPosition(combatant: ResCombatant, move: int, wait: float=0.35):
	var combatant_group
	if combatant is ResPlayerCombatant:
		combatant_group = team_container_markers
	else:
		combatant_group = enemy_container_markers
	var current_pos = combatant_group.find(combatant.SCENE.get_parent())
	if (move == 1 and current_pos-1 >= 0) or (move == -1 and current_pos+1 <= combatant_group.size()-1) or move == 0:
		var combatant_prev_pos = combatant.SCENE.global_position
		var tween_a = CombatGlobals.getCombatScene().create_tween().set_trans(Tween.TRANS_CUBIC)
		var tween_a_rotation = CombatGlobals.getCombatScene().create_tween().set_trans(Tween.TRANS_CUBIC) # ROTAT
		match move:
			1: 
				var combatant_b
				if combatant_group[current_pos-1].get_child_count() > 0:
					combatant_b = combatant_group[current_pos-1].get_child(0)
				else:
					combatant_b = combatant_group[current_pos-1]
				if combatant_b == null: combatant_b = combatant_group[current_pos-1]
				tween_a.tween_property(combatant.SCENE, 'global_position', combatant_b.global_position, 0.18)
				tween_a_rotation.tween_property(combatant.SCENE.get_node('Sprite2D'), 'rotation', 0.25, 0.15) # ROTAT
				combatant.SCENE.reparent(combatant_group[current_pos-1])
				if combatant_b is CombatantScene:
					var tween_b = CombatGlobals.getCombatScene().create_tween().set_trans(Tween.TRANS_CUBIC)
					var tween_b_rotation = CombatGlobals.getCombatScene().create_tween().set_trans(Tween.TRANS_CUBIC)
					tween_b.tween_property(combatant_b, 'global_position', combatant_prev_pos, 0.2)
					tween_b_rotation.tween_property(combatant_b.get_node('Sprite2D'), 'rotation', -0.25, 0.15) # ROTAT
					combatant_b.reparent(combatant_group[current_pos])
					tween_b_rotation.tween_property(combatant_b.get_node('Sprite2D'), 'rotation', 0, 0.15)# ROTAT
			-1: 
				var combatant_b
				if combatant_group[current_pos+1].get_child_count() > 0:
					combatant_b = combatant_group[current_pos+1].get_child(0)
				else:
					combatant_b = combatant_group[current_pos+1]
				tween_a.tween_property(combatant.SCENE, 'global_position', combatant_b.global_position, 0.18)
				tween_a_rotation.tween_property(combatant.SCENE.get_node('Sprite2D'), 'rotation', -0.25, 0.15)
				combatant.SCENE.reparent(combatant_group[current_pos+1])
				if combatant_b is CombatantScene:
					var tween_b = CombatGlobals.getCombatScene().create_tween().set_trans(Tween.TRANS_CUBIC)
					var tween_b_rotation = CombatGlobals.getCombatScene().create_tween().set_trans(Tween.TRANS_CUBIC) # ROTAT
					tween_b.tween_property(combatant_b, 'global_position', combatant_prev_pos, 0.2)
					tween_b_rotation.tween_property(combatant_b.get_node('Sprite2D'), 'rotation', 0.25, 0.15)# ROTAT
					combatant_b.reparent(combatant_group[current_pos])
					tween_b_rotation.tween_property(combatant_b.get_node('Sprite2D'), 'rotation', 0, 0.15)# ROTAT
			
		tween_a_rotation.tween_property(combatant.SCENE.get_node('Sprite2D'), 'rotation', 0, 0.15)# ROTAT
	
	await get_tree().create_timer(wait).timeout

func moveOnslaught(direction: int):
	if (direction==1 and onslaught_combatant.SCENE.global_position.x+32 > 48) or (direction==-1 and onslaught_combatant.SCENE.global_position.x-32 < -48):
		return
	
	tween_running = true
	var pos_tween = create_tween().set_trans(Tween.TRANS_BOUNCE)
	var move = 32 * direction
	pos_tween.tween_property(onslaught_combatant.SCENE, 'global_position', onslaught_combatant.SCENE.global_position+Vector2(move, 0), 0.1)
	await pos_tween.finished
	tween_running = false

func setOnslaught(combatant: ResPlayerCombatant, set_to:bool):
	active_combatant.SCENE.get_node('CombatBars').visible = false
	await fadeCombatant(active_combatant.SCENE, false)
	if !combatant.hasStatusEffect('Guard'):
		combatant.SCENE.setBlocking(set_to)
		combatant.SCENE.allow_block = set_to
	
	for target in COMBATANTS:
		if !target.hasStatusEffect('Knock Out') and target != combatant:
			target.SCENE.collision.disabled = set_to
	if set_to:
		team_hp_bar.process_mode = Node.PROCESS_MODE_ALWAYS
		onslaught_container.show()
		onslaught_container_animator.play("Show")
		previous_position = active_combatant.SCENE.get_parent().global_position
		active_combatant.SCENE.get_parent().global_position = Vector2(0, -16)
		onslaught_combatant = combatant
		var tween = CombatGlobals.getCombatScene().create_tween()
		tween.tween_property(combatant.SCENE, 'global_position', onslaught_container.get_children()[0].global_position, 0.25)
		await tween.finished
		CombatGlobals.getCombatScene().zoomCamera(Vector2(0.5,0.5))
	else:
		team_hp_bar.process_mode = Node.PROCESS_MODE_DISABLED
		onslaught_container_animator.play_backwards("Show")
		onslaught_combatant = null
		active_combatant.SCENE.get_parent().global_position = previous_position
		active_combatant.SCENE.get_node('CombatBars').visible = true
		active_combatant.SCENE.moveTo(active_combatant.SCENE.get_parent())
		await combatant.SCENE.moveTo(combatant.SCENE.get_parent())
		onslaught_container.hide()
		CombatGlobals.getCombatScene().zoomCamera(Vector2(-0.5,-0.5))
	
	onslaught_mode = set_to

func fadeCombatant(target: CombatantScene, fade_in: bool, duration: float=0.25):
	var tween = CombatGlobals.getCombatScene().create_tween()
	if fade_in:
		tween.tween_property(active_combatant.SCENE, 'modulate', Color(Color.WHITE, 1.0), duration)
	else:
		tween.tween_property(active_combatant.SCENE, 'modulate', Color(Color.WHITE, 0.0), duration)
	await tween.finished

func getCombatantPosition(combatant: ResCombatant=active_combatant)->int:
	if combatant is ResPlayerCombatant:
		return team_container_markers.find(combatant.SCENE.get_parent())
	else:
		return enemy_container_markers.find(combatant.SCENE.get_parent())

func sortCombatantsByPosition()-> Array[ResCombatant]:
	var out: Array[ResCombatant] = []
	var reversed_array = team_container_markers.duplicate()
	reversed_array.reverse()
	for combatant in reversed_array:
		if combatant.get_child_count() == 0: continue
		out.append(combatant.get_child(0).combatant_resource)
	for combatant in enemy_container_markers:
		if combatant.get_child_count() == 0: continue
		out.append(combatant.get_child(0).combatant_resource)
	return out

func addTargetClickButton(combatant: ResCombatant):
	var button = TextureButton.new()
	button.texture_hover = load("res://images/sprites/button_confirm_hover.png")
	button.texture_normal = load("res://images/sprites/button_confirm_normal.png")
	button.texture_pressed = load("res://images/sprites/button_confirm_click.png")
	button.pressed.connect(
		func(): 
			removeTargetButtons()
			if target_state == 1:
				target_combatant = combatant
			target_selected.emit()
			OverworldGlobals.playSound("56243__qk__latch_01.ogg")
	)
	button.mouse_entered.connect(func(): OverworldGlobals.playSound("342694__spacejoe__lock-2-remove-key-2.ogg"))
	button.z_index = 999
	button.name = 'TargetButton'
	button.grow_horizontal = Control.GROW_DIRECTION_BOTH
	button.grow_vertical = Control.GROW_DIRECTION_BOTH
	button.set_anchors_preset(Control.PRESET_CENTER)
	combatant.SCENE.add_child(button)
	button.position.y -= 24

func removeTargetButtons():
	for combatant in COMBATANTS:
		if combatant.SCENE.has_node('TargetButton'):
			combatant.SCENE.get_node('TargetButton').queue_free()
