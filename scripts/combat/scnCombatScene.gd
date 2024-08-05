extends Node2D
class_name CombatScene

@export var COMBATANTS: Array[ResCombatant]

@onready var combat_camera: DynamicCamera = $CombatCamera
@onready var combat_log = $CombatCamera/Interface/LogContainer
@onready var team_container_markers = $TeamContainer.get_children()
@onready var enemy_container_markers = $EnemyContainer.get_children()
@onready var secondary_panel = $CombatCamera/Interface/SecondaryPanel
@onready var secondary_action_panel = $CombatCamera/Interface/SecondaryPanel/OptionContainer
@onready var secondary_panel_container = $CombatCamera/Interface/SecondaryPanel/OptionContainer/Scroller/Container
@onready var secondary_description = $CombatCamera/Interface/SecondaryPanel/DescriptionPanel/MarginContainer/RichTextLabel
@onready var action_panel = $CombatCamera/Interface/ActionPanel/ActionPanel/MarginContainer/Buttons
@onready var escape_button = $CombatCamera/Interface/ActionPanel/ActionPanel/MarginContainer/Buttons/Escape
@onready var ability_slot_button = $CombatCamera/Interface/ActionPanel/ActionPanel/MarginContainer/Buttons/Guard
@onready var ui_inspect_target = $CombatCamera/Interface/Inspect
@onready var ui_attribute_view = $CombatCamera/Interface/Inspect/AttributeView
@onready var ui_status_inspect = $CombatCamera/Interface/Inspect/PanelContainer/StatusEffects
@onready var round_counter = $CombatCamera/Interface/Counts/RoundCounter
@onready var turn_counter = $CombatCamera/Interface/Counts/TurnCounter
@onready var transition_scene = $CombatCamera/BattleTransition
@onready var transition = $CombatCamera/BattleTransition.get_node('AnimationPlayer')
@onready var battle_music = $BattleMusic
@onready var battle_sounds = $BattleSounds
@onready var battle_back = $CombatCamera/DefaultBattleParallax.get_node('AnimationPlayer')
@onready var top_log_label = $CombatCamera/Interface/TopLog
@onready var top_log_animator = $CombatCamera/Interface/TopLog/AnimationPlayer
@onready var ui_animator = $CombatCamera/Interface/InterfaceAnimator

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
var experience_earnt = 0
var drops = {}
var turn_count = 0
var round_count = 0
var player_turn_count = 0
var enemy_turn_count = 0
var battle_music_path: String = ""
var combat_result: int = -1
var dogpile_count: int = 0
var camera_position: Vector2 = Vector2(0, 0)

signal confirm
signal target_selected
signal update_exp(value: float, max_value: float)
signal dialogue_done
signal combat_done

#********************************************************************************
# INITIALIZATION AND COMBAT LOOP
#********************************************************************************
func _ready():
	if OverworldGlobals.getCurrentMap().has_node('Balloon'):
		OverworldGlobals.getCurrentMap().get_node('Balloon').queue_free()
	
	transition_scene.visible = true
	CombatGlobals.execute_ability.connect(commandExecuteAbility)
	renameDuplicates()
	
	for combatant in COMBATANTS:
		combatant.initializeCombatant()
		combatant.player_turn.connect(on_player_turn)
		combatant.enemy_turn.connect(on_enemy_turn)
		
		if combatant is ResPlayerCombatant:
			addCombatant(combatant, team_container_markers)
		else:
			addCombatant(combatant, enemy_container_markers)
			combatant.STAT_VALUES['hustle'] += 2 * (dogpile_count+1)
		
		var combat_bars = preload("res://scenes/user_interface/CombatBars.tscn").instantiate()
		combat_bars.attached_combatant = combatant
		combatant.SCENE.add_child(combat_bars)
		
	if battle_music_path != "":
		battle_music.stream = load(battle_music_path)
		battle_music.play()
	
	transition.play('Out')
	await transition.animation_finished
	
	for combatant in COMBATANTS:
		tickStatusEffects(combatant)
	removeDeadCombatants(false)
	
	rollTurns()
	setActiveCombatant(false)
	while active_combatant.STAT_VALUES['hustle'] < 0:
		setActiveCombatant(false)
	
	for button in action_panel.get_children():
		button.focus_entered.connect(func(): secondary_panel.hide())
	battle_back.play('Show')
	#active_combatant.act()
	var player_combatant = getCombatantGroup('team')[0].SCENE
	var enemy_combatant = getCombatantGroup('enemies')[0]
	await player_combatant.moveTo(enemy_combatant)
	await player_combatant.doAttack()
	await player_combatant.moveTo(player_combatant.get_parent())
	
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
	if Input.is_action_just_pressed('ui_cancel') and secondary_panel.visible:
		resetActionLog()
	
	if Input.is_action_just_pressed('ui_home'):
		if action_panel.visible == true:
			toggleUI(false)
		else:
			toggleUI(true)

func on_player_turn():
	if has_node('QTE'):
		await CombatGlobals.qte_finished
	
	Input.action_release("ui_accept")
	
	resetActionLog()
	action_panel.show()
	action_panel.get_child(0).grab_focus()
	OverworldGlobals.playSound("658273__matrixxx__war-ready.ogg")
	ui_animator.play('ShowActionPanel')
	#playCombatAudio("658273__matrixxx__war-ready.ogg", 0.0, 1.0, true)
	if active_combatant.EQUIPPED_WEAPON != null:
		ability_slot_button.text = 'WPN'
		ability_slot_button.icon = active_combatant.EQUIPPED_WEAPON.ICON
	else:
		ability_slot_button.text = 'GUARD'
		ability_slot_button.icon = null
	await confirm
	end_turn()

func on_enemy_turn():
	#playCombatAudio("658273__matrixxx__war-ready.ogg", 0.0, 0.75, true)
	ui_animator.play_backwards('ShowActionPanel')
	if has_node('QTE'): await CombatGlobals.qte_finished
	if await checkWin(): return
	
	action_panel.hide()
	selected_ability = active_combatant.AI_PACKAGE.selectAbility(active_combatant.ABILITY_SET)
	valid_targets = selected_ability.getValidTargets(COMBATANTS, false)
	
	if selected_ability.getTargetType() == 1:
		target_combatant = active_combatant.AI_PACKAGE.selectTarget(valid_targets)
	else:
		target_combatant = valid_targets
	
	if (target_combatant != null):
		executeAbility()
		await confirm
	
	end_turn()

func end_turn(combatant_act=true):
	combat_camera.position = camera_position
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
		combat_log.writeCombatLog(combat_event.EVENT_MESSAGE)
		commandExecuteAbility(null, combat_event.ABILITY)
		await get_tree().create_timer(0.5).timeout
		if await checkWin(): return
	elif combat_event != null and turn_count % combat_event.TURN_TRIGGER == combat_event.TURN_TRIGGER - 3:
		combat_log.writeCombatLog(combat_event.WARNING_MESSAGE)
	
	var turn_title = 'turn/%s' % turn_count
	CombatGlobals.dialogue_signal.emit(turn_title)
	
	for combatant in COMBATANTS:
		if combatant.isDead(): continue
		refreshInstantCasts(combatant)
		tickStatusEffects(combatant, true)
		CombatGlobals.dialogue_signal.emit(combatant)
	removeDeadCombatants()
	
	# Reset values
	run_once = true
	target_index = 0
	secondary_panel.hide()
	
	# Determine next combatant
	if selected_ability == null or !selected_ability.INSTANT_CAST:
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
				experience_earnt += combatant.getExperience()
				addDrop(combatant.getDrops())
		elif combatant is ResPlayerCombatant:
			if !combatant.hasStatusEffect('Fading') and !combatant.hasStatusEffect('Knock Out') and fading: 
				clearStatusEffects(combatant)
				CombatGlobals.addStatusEffect(combatant, 'Fading', true)
				combatant.ACTED = true
			elif !combatant.getStatusEffectNames().has('Knock Out') and !fading:
				CombatGlobals.addStatusEffect(combatant, 'KnockOut', true)
				combatant.ACTED = true

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

func _on_items_pressed():
	getPlayerItems()
	if secondary_panel_container.get_child_count() == 0: return
	secondary_panel.show()
	secondary_panel_container.get_child(0).grab_focus()

func _on_inspect_pressed():
	target_state = 3

func _on_escape_pressed():
	var hustle_enemies = 0
	var hustle_allies = 0
	for combatant in getCombatantGroup('enemies'):
		if combatant.STAT_VALUES['hustle'] > 0:
			hustle_enemies += combatant.BASE_STAT_VALUES['hustle']
	for combatant in getCombatantGroup('team'):
		if combatant.STAT_VALUES['hustle'] > 0:
			hustle_allies += combatant.BASE_STAT_VALUES['hustle']
	var chance_escape = 0.25 + ((hustle_allies-hustle_enemies)*0.01)
	if CombatGlobals.randomRoll(chance_escape):
		CombatGlobals.combat_lost.emit(unique_id)
		concludeCombat(2)
	else:
		for combatant in getCombatantGroup('team'):
			CombatGlobals.addStatusEffect(combatant, 'Dazed', true)
		confirm.emit()

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
		child.free()
	
	for ability in ability_set:
		var button = OverworldGlobals.createCustomButton()
		button.add_theme_font_size_override('font_size', 16)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = ability.NAME
		button.pressed.connect(func(): forceCastAbility(ability))
		button.focus_entered.connect(func():updateDescription(ability))
		if !ability.ENABLED:
			button.disabled = true
		secondary_panel_container.add_child(button)

func getPlayerItems():
	for child in secondary_panel_container.get_children():
		child.free()
	
	for item in InventoryGlobals.INVENTORY:
		if !item is ResConsumable or item.EFFECT == null: continue
		var button = OverworldGlobals.createCustomButton()
		button.add_theme_font_size_override('font_size', 16)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.x = 240
		button.text = str(item.NAME, ' x', item.STACK)
		button.pressed.connect(
			func():
				if item.STACK > 0:
					forceCastAbility(item.EFFECT)
					item.take(1)
				)
		button.focus_entered.connect(func(): updateDescription(item.EFFECT))
		secondary_panel_container.add_child(button)

func getPlayerWeapons(inventory):
	for child in secondary_panel_container.get_children():
		child.free()
		
	for weapon in inventory:
		if !weapon is ResWeapon: continue
		var button = OverworldGlobals.createCustomButton()
		button.add_theme_font_size_override('font_size', 16)
		button.custom_minimum_size.x = 240
		button.text = str(weapon.NAME, '(', weapon.durability, '/', weapon.max_durability,')')
		button.pressed.connect(
			func():
				if weapon.durability > 0:
					forceCastAbility(weapon.EFFECT)
					weapon.useDurability())
		button.focus_entered.connect(
			func(): updateDescription(weapon.EFFECT.getRichDescription())
		)
		if weapon.durability <= 0 or !weapon.canUse(active_combatant): 
			button.disabled = true
		secondary_panel_container.add_child(button)

func playerSelectSingleTarget():
	if getCombatantGroup('enemies').is_empty():
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
	valid_targets = COMBATANTS
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
		return
	
	for effect in combatant.STATUS_EFFECTS:
		ui_status_inspect.text += OverworldGlobals.insertTextureCode(effect.TEXTURE) + effect.DESCRIPTION+'\n'

func executeAbility():
	# NOTE TO SELF, PRELOAD AI PACKAGES TO AVOID LAG SPIKES
	selected_ability.animateCast(active_combatant)
	selected_ability.applyEffects(
								active_combatant, 
								target_combatant, 
								selected_ability.ANIMATION
								)
	#writeTopLogMessage(selected_ability.NAME)
	await get_tree().create_timer(0.5).timeout
	if has_node('QTE'): 
		await CombatGlobals.qte_finished
		await get_node('QTE').tree_exited
	Input.action_release("ui_accept")
	
	var ability_title = 'ability/%s' % selected_ability.resource_path.get_file().trim_suffix('.tres')
	CombatGlobals.dialogue_signal.emit(ability_title)
	if checkDialogue():
		await DialogueManager.dialogue_ended
	confirm.emit()

func skipTurn():
	target_state = 0
	if run_once:
		Input.action_release("ui_accept")
		confirm.emit()
		action_panel.hide()
		run_once = false

func commandExecuteAbility(target, ability: ResAbility):
	ability.animateCast(active_combatant)
	if ability.TARGET_TYPE == ability.TargetType.MULTI:
		target = ability.getValidTargets(COMBATANTS, active_combatant is ResPlayerCombatant)
	ability.applyEffects(
						null, 
						target, 
						selected_ability.ANIMATION
						)

#********************************************************************************
# MISCELLANEOUS
#********************************************************************************
func moveCamera(target: Vector2, speed=0.25):
	create_tween().tween_property(combat_camera, 'global_position', target, speed)

func addCombatant(combatant, container):
	for marker in container:
		if marker.get_child_count() != 0: continue
		marker.add_child(combatant.SCENE)
		combatant.getAnimator().play('Idle')
		break

func forceCastAbility(ability: ResAbility):
	selected_ability = ability
	valid_targets = selected_ability.getValidTargets(COMBATANTS, true)
	target_state = selected_ability.getTargetType()
	updateDescription(ability)
	ui_animator.play('FocusDescription')
	secondary_action_panel.hide()
	action_panel.hide()
	await target_selected
	runAbility()

func updateDescription(ability: ResAbility):
	secondary_description.text = ability.getRichDescription()
	secondary_description.show()

func animateSecondaryPanel(animation: String):
	if animation == 'show':
		secondary_action_panel.show()
		secondary_panel.show()
		ui_animator.play("ShowSecondaryPanel")
	elif animation == 'hide':
		ui_animator.play_backwards("ShowDescriptionPanel")
		ui_animator.play_backwards("ShowOptionPanel")

func getDeadCombatants():
	return COMBATANTS.duplicate().filter(func getDead(combatant): return combatant.isDead())

func addDrop(loot_drops: Dictionary):
	for loot in loot_drops.keys():
		if drops.keys().has(loot):
			drops[loot] += loot_drops[loot]
		else:
			drops[loot] = loot_drops[loot]

func rollTurns():
	playCombatAudio("714571__matrixxx__reverse-time.ogg", 0.0, 1, true)
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

func clearStatusEffects(combatant: ResCombatant):
	while !combatant.STATUS_EFFECTS.is_empty():
		combatant.STATUS_EFFECTS[0].removeStatusEffect()

func tickStatusEffects(combatant: ResCombatant, per_turn = false):
	for effect in combatant.STATUS_EFFECTS:
		if per_turn and !effect.TICK_PER_TURN: continue
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
		OverworldGlobals.playSound("56243__qk__latch_01.ogg")
		target_selected.emit()
	if Input.is_action_just_pressed("ui_cancel"):
		ui_animator.play_backwards('FocusDescription')
		resetActionLog()
	
func resetActionLog():
	moveCamera(camera_position)
	#combat_camera.zoom = Vector2(1.0, 1.0)
	ui_inspect_target.hide()
	secondary_panel.hide()
	target_state = 0
	target_index = 0
	action_panel.get_child(0).grab_focus()
	action_panel.show()
	ui_animator.play('ShowActionPanel')

func runAbility():
	target_state = 0
	if run_once:
		executeAbility()
		action_panel.hide()
		run_once = false

func playCombatAudio(filename: String, db=0.0, pitch = 1, random_pitch=false):
	battle_sounds.pitch_scale = pitch
	battle_sounds.stream = load("res://audio/sounds/%s" % filename)
	battle_sounds.volume_db = db
	if random_pitch:
		randomize()
		battle_sounds.pitch_scale += randf_range(0.0, 0.25)
	battle_sounds.play()

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
		clearStatusEffects(combatant)
	action_panel.hide()
	secondary_panel.hide()
	target_state = 0
	target_index = 0
	var morale_bonus = 1
	var loot_bonus = 0
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
		if results == 1:
			experience_earnt += (experience_earnt*0.25)*morale_bonus
			for i in range(loot_bonus):
				for enemy in getCombatantGroup('enemies'): addDrop(enemy.getDrops())
	else:
		experience_earnt = -(PlayerGlobals.getRequiredExp()*0.2)
	
	var bc_ui = preload("res://scenes/user_interface/CombatResultScreen.tscn").instantiate()
	for item in drops.keys():
		InventoryGlobals.addItemResource(item, drops[item])
	add_child(bc_ui)
	if results == 1:
		bc_ui.title.text = 'Foes Neutralized!'
	else:
		bc_ui.title.text = 'Escaped!'
	bc_ui.setBonuses(all_bonuses)
	CombatGlobals.emit_exp_updated(experience_earnt, PlayerGlobals.getRequiredExp())
	PlayerGlobals.addExperience(experience_earnt)
	bc_ui.writeDrops(drops)
	
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
	queue_free()
