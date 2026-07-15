extends Node2D
class_name CombatScene

const COMBATANT_DISTANCE=42
const DEFAULT_ZOOM = Vector2(1.5,1.5)
var DEFAULT_CAM_POS: Vector2

enum TargetState {
	NONE,
	SINGLE,
	MULTI,
	INSPECT
}

#@export var combatants: Array[ResCombatant]
@onready var combat_camera = $CombatCamera
@onready var team_starting_pos = $TeamStartingPos.global_position
@onready var enemy_starting_pos = $EnemyStartingPos.global_position
#@onready var team_container_markers = $TeamContainer.get_children()
#@onready var enemy_container_markers = $EnemyContainer.get_children()
#@onready var transition_scene = $CombatCamera/BattleTransition
#@onready var transition = $CombatCamera/BattleTransition.get_node('AnimationPlayer')
@onready var battle_music = $BattleMusic
@onready var battle_back = $ParallaxBackground/AnimationPlayer
@onready var turn_timer_bar = $CombatCamera/Interface/TurnTimerBar
@onready var turn_timer_animator = $CombatCamera/Interface/TurnTimerBar/AnimationPlayer
@onready var turn_timer = $TurnTimer
#@onready var fade_bars_animator = $CombatCamera/FadeBars/AnimationPlayer
#@onready var ui_inspect_target = $CombatCamera/Interface/Inspect
#@onready var ui_attribute_view = $CombatCamera/Interface/Inspect/AttributeView
@onready var combat_ui: CombatUI = $CombatCamera/Interface/CombatUI
@onready var tension_magnet = $CombatCamera/TensionMagnet

var combatant_positions = {
	'team': [null,null,null,null],
	'enemies': [null,null,null,null]
}
var combatant_turn_order: Array
var combat_dialogue: CombatDialogue
var unique_id: String
var active_combatant: ResCombatant
var valid_targets
var target_combatant
var inspect_combatant
var combat_event: ResCombatEvent
var selected_ability: ResAbility
var run_once = true
#var total_experience = 0
var turn_count = 0
var round_count = 0
var player_turn_count = 0
var enemy_turn_count = 0
var battle_music_path: String = ""
var combat_result: int = -1

#var default_camera_zoom:Vector2 = Vector2(1.6,1.6)
var enemy_reinforcements: Array[ResCombatant]
var bonus_escape_chance = 1.0
#var onslaught_mode = false
#var onslaught_combatant: ResPlayerCombatant
var previous_position: Vector2
var previous_position_player: Vector2
var tween_running
var can_escape
var do_reinforcements:bool
var last_used_ability: Dictionary = {}
var ability_charge_tracker: Dictionary = {}
var turn_time: float = 0.0
var is_combatant_moving = false
var initial_damage: float = 0.0
var combat_entity
var reward_bank={
	'experience':0,
	'loot':{}
	}
var reinforcements_summoning:bool=false
var slain_enemies: Array[ResEnemyCombatant] = []
# ex.
#{
# <round>: {
#	<combatant>: [<ability>,<ability>],
#	<combatant>: [<ability>]
#	},
# ... and so on
#}
var ability_history = {}
var ability_executing:bool=false
var rebuking:bool=false
var targeting:bool=false

signal confirm
signal target_selected
signal update_exp(value: float, max_value: float)
signal move_finished
signal dialogue_done
signal combat_done
signal active_combatant_changed(combatant:ResCombatant)
signal targeting_started(target_selection:Array[ResCombatant])
signal targeting_ended
signal target_hovered(combatant)
signal target_exit_hover(combatant)
signal rebuke_finished
signal round_concluded

#********************************************************************************
# INITIALIZATION AND COMBAT LOOP
#********************************************************************************
func initializeCombat(combatants:Array[ResCombatant]):
	DEFAULT_CAM_POS = combat_camera.global_position
	#flasher.show()
	#team_hp_bar.process_mode = Node.PROCESS_MODE_DISABLED
	#print('REINFORCEMENTS: ',enemy_reinforcements)
	if OverworldGlobals.getCurrentMap().has_node('Balloon'):
		OverworldGlobals.getCurrentMap().get_node('Balloon').queue_free()
	
	#transition_scene.visible = true
	CombatGlobals.execute_ability.connect(commandExecuteAbility)
	renameDuplicates()
	
	battle_back.play('Show')
	#transition.play('Out')
	#await transition.animation_finished
	
	var dead_combatants = []
	for combatant in combatants:
		if combatant.isDead(): 
			dead_combatants.append(combatant)
			continue
		await addCombatant(combatant, false, '')
	for combatant in dead_combatants:
		combatants.erase(combatant)
	if battle_music_path != "":
		battle_music.stream = load(battle_music_path)
		battle_music.play()
	
	# ACTIVATE COMBAT START STATUSES!
	for combatant in combatants:
		tickStatusEffects(combatant, -1)
	
	if initial_damage > 0.0:
		for combatant in combatant_positions['enemies']:
			if combatant == null: continue
			await get_tree().create_timer(0.1).timeout
			CombatGlobals.calculateRawDamage(combatant, combatant.getMaxHealth()*initial_damage)
	
	await removeDeadCombatants(false)
	#combatant_positions['team'].reverse()
	rollTurns()
	setActiveCombatant(false)
	while active_combatant.isImmobilized():
		setActiveCombatant(false)
	enemy_reinforcements = enemy_reinforcements.filter(func(combatant): return combatant != null)
	active_combatant.act()
	if combat_dialogue != null:
		combat_dialogue.initialize()
	
	#transition_scene.visible = false
	UIGlobals.setControllerAdapter(true)
	
	if OverworldGlobals.getCurrentMap().has_node('StalkerEngage'):
		OverworldGlobals.getCurrentMap().get_node('StalkerEngage').queue_free()
	if OverworldGlobals.getCurrentMap().has_node('Stalker'):
		OverworldGlobals.getCurrentMap().get_node('Stalker').modulate = Color.WHITE
	#print('ENFORCEMENTS: ', enemy_reinforcements)
	combat_ui.initialize()
	combat_ui.inspector.setCombatant(active_combatant)

func getAllCombatants()-> Array[ResCombatant]:
	var all_combatants: Array[ResCombatant] = [] 
	all_combatants.append_array(combatant_positions['team'])
	all_combatants.append_array(combatant_positions['enemies'])
	all_combatants = all_combatants.filter(func(combatant): return combatant != null)
	#print(all_combatants, ' poopoo')
	return all_combatants

#func sortByPosition(combatant_a, combatant_b):
#	return getCombatantPosition(combatant_a) < getCombatantPosition(combatant_b)

func getCombatantNames():
	var out = []
	for combatant in getAllCombatants():
		out.append(combatant.name)
	return out

#func _process(_delta):
#	print('TP ', CombatGlobals.tension)

#func _process(_delta):
#	match target_state:
#		TargetState.SINGLE: playerSelectSingleTarget()
#		TargetState.MULTI: playerSelectMultiTarget()
#		TargetState.INSPECT: playerSelectInspection()

func _unhandled_input(_event):
#	if onslaught_mode and Input.is_action_just_pressed('ui_left') and !tween_running and onslaught_combatant != null and !onslaught_combatant.isDead():
#		moveOnslaught(-1)
#	if onslaught_mode and Input.is_action_just_pressed('ui_right') and !tween_running and onslaught_combatant != null and !onslaught_combatant.isDead():
#		moveOnslaught(1)
	
	if (Input.is_action_just_pressed('ui_cancel') or Input.is_action_just_pressed("ui_show_menu")  or Input.is_action_just_pressed("ui_right_mouse")) and !ability_executing: 
		#pass
		resetUI()
	
	if targeting and Input.is_action_just_pressed("ui_right"):
		OverworldGlobals.playSound("342694__spacejoe__lock-2-remove-key-2.ogg")
		if isInspecting(): 
			moveInspect('right')
			#inspectTarget(false)
		else:
			moveTarget('right')
	if targeting and Input.is_action_just_pressed("ui_left"):
		OverworldGlobals.playSound("342694__spacejoe__lock-2-remove-key-2.ogg")
		if isInspecting(): 
			moveInspect('left')
			#inspectTarget()
		else:
			moveTarget('left')
	if targeting and Input.is_action_just_pressed("ui_accept"):
		if isInspecting(): releaseInspect()
	#	removeTargetButtons()
		OverworldGlobals.playSound("56243__qk__latch_01.ogg")
		target_selected.emit()
	#if targeting and Input.is_action_just_pressed("ui_tab") or Input.is_action_just_pressed("ui_right_mouse") or Input.is_action_just_pressed("ui_cancel"):
	#	removeTargetButtons()
	if targeting and Input.is_action_pressed("ui_show_info") and !isInspecting():
		print('inspecting!')
		inspectTarget(true)
	elif targeting and Input.is_action_just_released("ui_show_info") and isInspecting():
		print('releasing!')
		releaseInspect()

func on_player_turn():
	ability_executing=false
	active_combatant_changed.emit(active_combatant)
	if active_combatant.ai_package != null: #and round_count < 64:
		if has_node('QTE'): await CombatGlobals.qte_finished
		if await checkWin(): return
		await useAIPackage()
		return
#	elif round_count == 64:
#		OverworldGlobals.playSound("res://audio/sounds/263652__jobro__mgs-detected-lead.ogg")
#		attemptEscape()
	
	Input.action_release("ui_accept")
	if rebuking:
		await rebuke_finished
	print(DEFAULT_CAM_POS)
	moveCamera(DEFAULT_CAM_POS)
	combat_ui.showAbilities(active_combatant)
#	if do_reinforcements and doReinforcementWarning():
#		OverworldGlobals.playSound("res://audio/sounds/39_Absorb_04.ogg")
#		print('WWARNING!!!!!!!!!!!!!!')
	if turn_time > 0.0:
		startTimer()
	await confirm
	end_turn()

func on_enemy_turn():
	ability_executing=false
	active_combatant_changed.emit(active_combatant)
	if has_node('QTE'): 
		await CombatGlobals.qte_finished
	if await checkWin(): 
		return
	combat_ui.hideUI()
	await useAIPackage()

func useAIPackage():
	selected_ability = active_combatant.ai_package.selectAbility(active_combatant.ability_set, active_combatant)
	if selected_ability != null and !active_combatant.isDead(true):
		valid_targets = selected_ability.getValidTargets(getOrderedCombatants(), active_combatant is ResPlayerCombatant)
		if selected_ability.getTargetType() == 1 and selected_ability.target_group != 2:
			target_combatant = active_combatant.ai_package.selectTarget(valid_targets)
		else:
			target_combatant = valid_targets
		if target_combatant != null:
			if selected_ability.charges > 0: updateAbilityChargeTracker(active_combatant, selected_ability)
			executeAbility()
		#if active_combatant.isDead(): print('XXX ', selected_ability)
	elif !active_combatant.isDead(true):
		showCannotAct('Pass!', true)
	
	if !active_combatant.isDead(true):
		await confirm
		
	end_turn()

func playRebukeText():
	$CombatCamera/Interface/RichTextLabel/AnimationPlayer.play('Show')

func end_turn(combatant_act=true):
	if combat_camera.zoom != DEFAULT_ZOOM:
		setCameraZoom(DEFAULT_ZOOM)
	for combatant in getAllCombatants():
		if !combatant.combatant_scene.has_node('CombatBars'):continue
		combatant.combatant_scene.get_node('CombatBars').setStatusVisibility(true)
	
	if !turn_timer.is_stopped(): 
		stopTimer()
	if await checkWin(): 
		return
	for combatant in getAllCombatants(): # Check for survivors!
		if combatant.isDead(true): continue
		CombatGlobals.dialogue_signal.emit(combatant)
	if combatant_act and !usedInstantCastAbility():
		active_combatant.turn_charges -= 1
		combatant_turn_order.remove_at(0)
		if active_combatant.turn_charges <= 0:
			tickStatusEffects(active_combatant, ResStatusEffect.TickType.TURN_END)
			active_combatant.tickTemporaryModifiers('turns')
			active_combatant.acted = true
	
	if allCombatantsActed() and combatant_turn_order.is_empty():
		rollTurns()
		end_turn(false)
		return
	
	turn_count += 1
	if active_combatant is ResPlayerCombatant:
		player_turn_count += 1
	else:
		enemy_turn_count += 1
	
	if is_combatant_moving:
		#await move_finished
		await get_tree().create_timer(0.25).timeout
		is_combatant_moving = false
		#await get_tree().create_timer(0.25).timeout
	
	if combat_event != null and turn_count % combat_event.turn_trigger == 0:
		combat_ui.writeCombatLog(combat_event.event_message)
		commandExecuteAbility(null, combat_event.ability)
		await get_tree().create_timer(2.0).timeout
		if await checkWin(): return
	elif combat_event != null and turn_count % combat_event.turn_trigger == combat_event.turn_trigger - 3:
		combat_ui.writeCombatLog(combat_event.warning_message)
	
	var turn_title = 'turn/%s' % turn_count
	CombatGlobals.dialogue_signal.emit(turn_title)
	
	for combatant in getAllCombatants():
		if combatant.isDead(true): continue
		#refreshInstantCasts(combatant)
		if !usedInstantCastAbility(): 
			tickStatusEffects(combatant, ResStatusEffect.TickType.PER_TURN) # Tick PER TURN statuses (e.g. tick even tho its not the combatant's)
		CombatGlobals.dialogue_signal.emit(combatant)
	removeDeadCombatants()
	
	
	# Reset values
	run_once = true
	#target_index = 0
	
		
	# Determine next combatant
	if !usedInstantCastAbility():
		if has_node('QTE'):
			await CombatGlobals.qte_finished
			await get_node('QTE').tree_exited
		setActiveCombatant()
	
	if active_combatant is ResPlayerCombatant:
		active_combatant.applyAbilityMutations()
	else:
		active_combatant.clearAbilityMutations()
	active_combatant.resolve_dot_shield = false
	if checkDialogue():
		await DialogueManager.dialogue_ended
	
	if !active_combatant.isImmobilized():
		active_combatant.removeTokens(ResStatusEffect.RemoveType.ON_TURN)
		active_combatant.act()
#		active_combatant.combatant_scene.get_node('CombatBars').pulse_gradient.play('Show')
	else:
		if is_instance_valid(active_combatant.combatant_scene) and !active_combatant.isDead(true):
			if target_combatant is ResCombatant and !target_combatant.hasStatusEffect('Guard'): 
				#print('moving to active !')
				shiftCamera(active_combatant)
				#moveCamera(active_combatant.combatant_scene.global_position)
			active_combatant.removeTokens(ResStatusEffect.RemoveType.ON_TURN)
			active_combatant_changed.emit(active_combatant)
			await showCannotAct('[color=%s][img color=%s outline=1]res://images/status_icons/icon_stun.png[/img] Stunned!' % ['STEEL_BLUE', 'STEEL_BLUE']) # DUCT TAPE
		end_turn()
		return
	if await checkWin(): 
		return

func usedInstantCastAbility():
	return selected_ability != null and selected_ability.instant_cast

func canCallReinforcements()->bool:
	
	var party_sizes_valid = getLivingCombatants('enemies').size() <= 2 and getLivingCombatants('team').size() >= 2
	var no_attacks = false
	if round_count > 3:
		no_attacks = damageAbilityUsed(round_count-1, 'team') < 2 and \
					damageAbilityUsed(round_count-2, 'team')  < 2
	
	return do_reinforcements and no_attacks and party_sizes_valid and !reinforcements_summoning

#func doReinforcementWarning():
#	if reinforcements_summoning:
#		return false
#
#	var party_sizes_valid = getLivingCombatants('enemies').size() <= 2 and getLivingCombatants('team').size() >= 2
#	var no_attacks = false
#	if round_count > 3:
#		no_attacks = damageAbilityUsed(round_count-1, 'team') < 2 and \
#					damageAbilityUsed(round_count, 'team')  < 2
#
#	return party_sizes_valid and no_attacks

func showCannotAct(message:String,emit_confirm:bool=false):
	shiftCamera(active_combatant)
	CombatGlobals.manual_call_indicator.emit(active_combatant, message, 'Show')
	selected_ability = null
	await get_tree().create_timer(1.25).timeout
	if emit_confirm:
		confirm.emit()

func setActiveCombatant(tick_effect=true):
	active_combatant = combatant_turn_order[0][0]
	if tick_effect:
		tickStatusEffects(active_combatant, ResStatusEffect.TickType.TURN_START) # Tick ON TURN statuses (e.g. tick only on combatant's turn)
		#active_combatant.tickTemporaryModifiers('turns')
		removeDeadCombatants()

func getTickOnTurnEffects(combatant: ResCombatant):
	var out = []
	for effect in combatant.status_effects:
		if !effect.tick_any_turn: out.append(effect)
	return out

func removeDeadCombatants(is_valid_check=true):
	if !isCombatValid() and is_valid_check: return
	
	for combatant in getDeadCombatants():
		combatant.removeTokens(ResStatusEffect.RemoveType.ON_TURN)
		if !combatant.isDead(true): 
			combatant.acted = true
		if combatant is ResEnemyCombatant:
			getEnemyDrops(combatant)
			slain_enemies.append(combatant)
			if combatant.spawn_on_death != null:
				replaceCombatant(combatant, combatant.spawn_on_death) ## Also keeping this!

func getEnemyDrops(combatant:ResEnemyCombatant):
	if combatant.items_dropped: return
	
	#CombatGlobals.manual_call_indicator.emit(combatant, '+'+str(combatant.getExperience())+' EXP','Show',true)
	#print('added exp: ', combatant.getExperience())
	#print('added loot: ', combatant.getDrops())
	reward_bank = CombatGlobals.combineDictionaries(reward_bank, {'experience': combatant.getExperience()})
	reward_bank['loot'] = CombatGlobals.combineDictionaries(reward_bank['loot'], combatant.getDrops())
	combatant.items_dropped=true

func getLivingCombatants(group:String):
	return combatant_positions[group].filter(
		func(combatant:ResCombatant): 
			return combatant != null and !combatant.isDead(true)
			)

#********************************************************************************
# BASE combatant_scene NODE CONTROL
#********************************************************************************
func calculateEscapeChance()-> float:
	var hustle_enemies = 0
	var hustle_allies = 0
	for combatant in getLivingCombatants('enemies'):
		hustle_enemies += combatant.base_stat_values['speed']
	for combatant in getLivingCombatants('team'):
		hustle_allies += combatant.base_stat_values['speed']
	return snappedf((0.15 + ((hustle_allies-hustle_enemies)*0.01)) + bonus_escape_chance, 0.01)

func toggleUI(visibility: bool): 
#	TEMP
#	for marker in enemy_container_markers:
#		if marker.get_child_count() != 0:
#			marker.get_child(0).get_node('CombatBars').visible = visibility
#	for marker in team_container_markers:
#		if marker.get_child_count() != 0:
#			marker.get_child(0).get_node('CombatBars').visible = visibility
	
	for child in combat_camera.get_children():
		if child is Control:
			child.visible = visibility
	
	if visibility: 
		pass
		#resetActionLog()

func setUIModulation(ui_modulate: Color, duration:float=0.1):
#	for marker in enemy_container_markers:
#		if marker.get_child_count() != 0 and marker.get_child(0).has_node('CombatBars'):
#			create_tween().tween_property(marker.get_child(0).get_node('CombatBars'), 'modulate', ui_modulate, duration)
#	for marker in team_container_markers:
#		if marker.get_child_count() != 0 and marker.get_child(0).has_node('CombatBars'):
#			create_tween().tween_property(marker.get_child(0).get_node('CombatBars'), 'modulate', ui_modulate, duration)
	
	for child in combat_camera.get_children():
		if child is Control:
			create_tween().tween_property(child, 'modulate', ui_modulate, duration)
	for combatant in getAllCombatants():
		var bars = combatant.combatant_scene.get_node('CombatBars')
		create_tween().tween_property(bars, 'modulate', ui_modulate, duration)
#********************************************************************************
# ability SELECTION, TARGETING, AND EXECUTION
#********************************************************************************
#func inspectTarget(inspect:bool):
#	if !target_combatant is ResCombatant: return
#
#	ui_attribute_view.combatant = target_combatant
#	if inspect:
#		ui_inspect_target.show()
#		zoomCamera(Vector2(0.25,0.25))
#	else:
#		zoomCamera(Vector2(-0.25,-0.25))
#		ui_inspect_target.hide()

func removeTargetToken(target, caster):
	if target is ResCombatant and !CombatGlobals.isSameCombatantType(target,caster):
		target_combatant.removeTokens(ResStatusEffect.RemoveType.GET_TARGETED)

func removeRoundStartTokens():
	for combatant in getAllCombatants():
		combatant.removeTokens(ResStatusEffect.RemoveType.ROUND_START)

func executeAbility():
	ability_executing=true
	if !turn_timer.is_stopped(): 
		stopTimer()
	active_combatant.combatant_scene.z_index = 100
	fadeOutUntargeted()
#	for combatant in getAllCombatants():
#		if target_combatant is ResCombatant and ((target_combatant != combatant and active_combatant != combatant) or (target_combatant is Array and !target_combatant.has(combatant) and active_combatant != combatant)):
#			CombatGlobals.setCombatantVisibility(combatant.combatant_scene, false)
	if target_combatant is ResPlayerCombatant:
		allowBlocking(target_combatant)
	elif target_combatant is Array:
		for target in target_combatant: allowBlocking(target)
	
	if active_combatant is ResPlayerCombatant:
		CombatGlobals.addTension(-selected_ability.tension_cost)
	last_used_ability[active_combatant] = [selected_ability, target_combatant]
	recordAbilityHistory(active_combatant, selected_ability)
	
	await get_tree().create_timer(0.25).timeout
	if target_combatant is ResCombatant:
		selected_ability.ability_script.animate(active_combatant.combatant_scene, target_combatant.combatant_scene, selected_ability)
	else:
		selected_ability.ability_script.animate(active_combatant.combatant_scene, target_combatant, selected_ability)
	shiftCamera(target_combatant[0] if target_combatant is Array else target_combatant)
	CombatGlobals.ability_casted.emit(selected_ability)
	await CombatGlobals.ability_finished
	if has_node('QTE'):
		await CombatGlobals.qte_finished
		await get_node('QTE').tree_exited
	Input.action_release("ui_accept")
	fadeInAllCombatants()
	var ability_title = 'ability/%s' % selected_ability.resource_path.get_file().trim_suffix('.tres')
	CombatGlobals.dialogue_signal.emit(ability_title)
	if checkDialogue():
		await DialogueManager.dialogue_ended
	if (target_combatant is  ResCombatant and is_instance_valid(target_combatant.combatant_scene)):
		removeTargetToken(target_combatant, active_combatant)
		revokeBlocking(target_combatant)
	elif target_combatant is Array:
		for target in target_combatant:
			removeTargetToken(target_combatant, active_combatant)
			revokeBlocking(target)
	
	await get_tree().process_frame # Attempt to fix combatants standing there like idiots, keep an eye out
	confirm.emit()

func fadeInAllCombatants():
	for combatant in getAllCombatants():
		CombatGlobals.setCombatantVisibility(combatant.combatant_scene, true)

func fadeOutUntargeted(inspecting:bool=false):
	var excempt_combatant = target_combatant if !inspecting else inspect_combatant
	
	for combatant in getAllCombatants():
		if combatant == active_combatant and !inspecting:
			continue
		if (excempt_combatant is ResCombatant and  combatant == excempt_combatant) or (excempt_combatant is Array and excempt_combatant.has(combatant)):
			continue
		CombatGlobals.setCombatantVisibility(combatant.combatant_scene, false)

func recordAbilityHistory(acting_combatant:ResCombatant, use_ability:ResAbility):
	if !ability_history.has(round_count):
		ability_history[round_count] = {}
	if ability_history.size() >= 8:
		ability_history.erase(ability_history.keys()[0])
	
	if ability_history[round_count].has(acting_combatant):
		var record = {acting_combatant:[use_ability]}
		ability_history[round_count] = CombatGlobals.combineDictionaries(ability_history[round_count], record)
	else:
		ability_history[round_count][acting_combatant] = [use_ability]

func damageAbilityUsed(check_round:int, team:String):
	assert (team == 'team' or team == 'enemies', 'Team parameter should only be "team" or "enemies"')
	var count = 0
	for acted_combatant in ability_history[check_round]:
		if (acted_combatant is ResEnemyCombatant and team == 'team') or (acted_combatant is ResPlayerCombatant and team == 'enemies'):
			continue
		
		for ability in ability_history[check_round][acted_combatant]:
			if ability.isDamaging(): count += 1
	
	return count

func allowBlocking(target: ResCombatant):
	if target is ResPlayerCombatant and target.combatant_scene.blocking and active_combatant is ResEnemyCombatant:
		target.combatant_scene.allow_block = true
		CombatGlobals.showWarning(target.combatant_scene)
		if target.combatant_scene.has_node('CombatBars'):
			target.combatant_scene.get_node('CombatBars').setStatusVisibility(false)
			active_combatant.combatant_scene.get_node('CombatBars').setStatusVisibility(false)

func revokeBlocking(target: ResCombatant):
	if target is ResPlayerCombatant and target.combatant_scene.blocking and active_combatant is ResEnemyCombatant:
		target.combatant_scene.allow_block = false

func skipTurn():
	#target_state = TargetState.NONE
	if run_once:
		Input.action_release("ui_accept")
		confirm.emit()
		run_once = false

# For executing combat events and such.
func commandExecuteAbility(target, ability: ResAbility):
	if ability.target_type == ResAbility.TargetType.MULTI:
		target = ability.getValidTargets(getAllCombatants(), active_combatant is ResPlayerCombatant)
	if ability.isBasicAbility():
		ability.ability_script.animate(null, target, ability)
	ability.ability_script.applyEffects(null, target, ability)
	
#********************************************************************************
# MISCELLANEOUS
#********************************************************************************
func moveCamera(target: Vector2, speed=0.25):#, flattened:bool=true):
	#return
	var tween = create_tween()
	tween.tween_property(combat_camera, 'global_position', target, speed)
	await tween.finished

func shiftCamera(target:ResCombatant):
	var shift = Vector2(8 * (-1 if target is ResPlayerCombatant else 1),0)
	moveCamera(DEFAULT_CAM_POS+shift,0.1)

func zoomCamera(zoom: Vector2, speed=0.25):
	var tween = create_tween()
	tween.tween_property(combat_camera, 'zoom', combat_camera.zoom+zoom, speed)
	await tween.finished

func setCameraZoom(set_zoom: Vector2, speed=0.25):
	var tween = create_tween()
	tween.tween_property(combat_camera, 'zoom', set_zoom, speed)
	await tween.finished

func addCombatant(combatant:ResCombatant, spawned:bool=false, animation_path:String=''):
	if !isCombatValid() and round_count > 0:
		return
	var allegiance = 'team' if combatant is ResPlayerCombatant else 'enemies'
	combatant.initializeCombatant()
	setSignals(combatant,true)
	
	if combatant.assigned_position != -1 and combatant_positions[allegiance][combatant.assigned_position] == null:
		combatant_positions[allegiance][combatant.assigned_position] = combatant
	else:
		autoFillPosition(combatant, allegiance)
	addCombatantScene(combatant, getCombatantPosition(combatant))
	
	if combatant is ResEnemyCombatant and combatant.is_converted:
		combatant.combatant_scene.rotation_degrees = -180
		combatant.combatant_scene.get_node('Sprite2D').flip_v = true
	if spawned:
		combatant.acted = false
		combatant.turn_charges = combatant.max_turn_charges
		combatant.name += ' SUMMONED'
		for turn_charge in range(combatant.max_turn_charges):
			var rolled_speed = randi_range(1, 8) + combatant.stat_values['speed']
			combatant_turn_order.append([combatant, rolled_speed])
	
	giveCombatBar(combatant)
	
	combatant.combatant_scene.doAnimation('Idle')
	if animation_path != '':
		await CombatGlobals.playAbilityAnimation(combatant, load(animation_path), 0.15)
	combatant.startBreatheTween(true)

func addCombatantScene(combatant:ResCombatant,pos:int):
	var scene = combatant.combatant_scene
	var offset = Vector2(-COMBATANT_DISTANCE,0) if combatant is ResPlayerCombatant else Vector2(COMBATANT_DISTANCE,0)
	var starting_pos = team_starting_pos if combatant is ResPlayerCombatant else enemy_starting_pos
	var rank = pos
	add_child(scene)
	scene.global_position = starting_pos + (offset * rank)

func getRankPosition(combatant:ResCombatant):
	var offset = Vector2(-COMBATANT_DISTANCE,0) if combatant is ResPlayerCombatant else Vector2(COMBATANT_DISTANCE,0)
	var starting_pos = team_starting_pos if combatant is ResPlayerCombatant else enemy_starting_pos
	var rank = getCombatantPosition(combatant)
	return starting_pos + (offset * rank)

func autoFillPosition(combatant:ResCombatant, allegiance:String):
	#var spot_index=0
	for spot in range(combatant_positions[allegiance].size()):
		if combatant_positions[allegiance][spot] != null: continue
		
		combatant_positions[allegiance][spot] = combatant
		return

func giveCombatBar(combatant:ResCombatant):
	var combat_bars = load("res://scenes/user_interface/CombatBars.tscn").instantiate()
	combat_bars.attached_combatant = combatant
	active_combatant_changed.connect(combat_bars.pulseTurn)
	targeting_started.connect(combat_bars.showTargetSelector)
	targeting_ended.connect(combat_bars.hideTargetSelector)
	target_hovered.connect(combat_bars.showGradientHover)
	combatant.combatant_scene.add_child(combat_bars)
	combatant.combatant_scene.get_node('CombatBars').attached_combatant = combatant
	combatant.combatant_scene.get_node('CombatBars').show()

func replaceCombatant(combatant: ResCombatant, new_combatant: ResCombatant, animation_path:String='', remove_drops:bool=true):
#	if combatant.name.contains('SUMMONED'):
#		print('aattempted!')
#		return
	
	await removeCombatant(combatant)
	if remove_drops:
		new_combatant.drop_pool.clear()
		new_combatant.experience_multiplier = 0
	addCombatant(new_combatant, true)
	if animation_path != '':
		await CombatGlobals.playAbilityAnimation(new_combatant, load(animation_path), 0.15)

func removeCombatant(combatant: ResCombatant):
	var combatant_group = getCombatantGroup(combatant)
	var group = 'enemies' if combatant is ResEnemyCombatant else 'team'
	#print('cunt: ', combatant_group)
	var combatant_index = combatant_group.find(combatant)
	#combatant.combatant_scene.get_parent().get_node('CombatBars').hide()
	setSignals(combatant,false)
	combatant_turn_order.erase(combatant)
	combatant.combatant_scene.queue_free()
	combatant_positions[group][combatant_index] = null
	#combatant_group[combatant_index] = null
	await combatant.combatant_scene.tree_exited

# Cast Ability for players
func forceCastAbility(ability: ResAbility, weapon: ResWeapon=null):
	targeting=true
	selected_ability = ability
	var target_selection:Array[ResCombatant] = []
	target_selection.assign(selected_ability.getValidTargets(getOrderedCombatants(), true)) 
	valid_targets = target_selection
	moveTarget('')
	targeting_started.emit(target_selection)
	
#	if ability.target_type == ResAbility.TargetType.MULTI:
#		addTargetClickButton(active_combatant)
#	elif valid_targets is Array:
#		for target in valid_targets: addTargetClickButton(target)
#	else:
#		addTargetClickButton(valid_targets)
	#target_state = selected_ability.getTargetType()
	if last_used_ability.keys().has(active_combatant) and last_used_ability[active_combatant][0] == ability and ability.target_type == ability.TargetType.SINGLE:
		moveTarget(last_used_ability[active_combatant][1])
	await target_selected
	targeting=false
	targeting_ended.emit()
	runAbility()
	if weapon != null: 
		weapon.useDurability(active_combatant)
	if ability.charges > 0:
		updateAbilityChargeTracker(active_combatant, ability)

func updateAbilityChargeTracker(caster: ResCombatant, ability: ResAbility):
	if ability_charge_tracker.has(caster) and ability_charge_tracker[caster].has(ability):
		ability_charge_tracker[caster][ability] -= 1
	elif ability_charge_tracker.has(caster) and !ability_charge_tracker[caster].has(ability):
		ability_charge_tracker[caster][ability] = ability.charges-1
	else:
		ability_charge_tracker[caster] = {ability:ability.charges-1}

func getChargesLeft(combatant: ResCombatant, ability: ResAbility):
	if ability_charge_tracker.has(combatant) and ability_charge_tracker[combatant].has(ability):
		return ability_charge_tracker[combatant][ability]
	else:
		return ability.charges

func getDeadCombatants(type: String=''):
	var combatants = []
	if type == '':
		combatants.append_array(combatant_positions['team'])
		combatants.append_array(combatant_positions['enemies'])
	else:
		combatants = combatant_positions[type]
	
	return combatants.filter(func(combatant:ResCombatant): return combatant != null and combatant.isDead(true)) #dead_combatants.filter(func getDead(combatant): return combatant.isDead(return combatant != null and true))

func rollTurns():
	removeRoundStartTokens()
	for combatant in getAllCombatants():
		tickStatusEffects(combatant, ResStatusEffect.TickType.ROUND_START)
	combatant_turn_order.clear()
	for combatant in getAllCombatants():
		if combatant.isDead(true):
			continue
		randomize()
		combatant.acted = false
		combatant.turn_charges = combatant.max_turn_charges
		for turn_charge in range(combatant.max_turn_charges):
			var rolled_speed = randi_range(1, 8) + combatant.stat_values['speed']
			combatant_turn_order.append([combatant, rolled_speed])
	combatant_turn_order.sort_custom(func(a, b): return a[1] > b[1])
	round_count += 1
#	combat_ui.updateRoundCounter(round_count)
	if !ability_history.has(round_count): 
		ability_history[round_count] = {}
	if canCallReinforcements():
		var caller = getLivingCombatants('enemies').pick_random()
		CombatGlobals.addStatusEffect(caller, 'CallingReinforcements')
	round_concluded.emit()

func callReinforcements():
	combat_camera.flash(SettingsGlobals.ui_colors['unique'], 0.5,0.05,1.0)
	var animation_path = "res://scenes/animations_abilities/Reinforcements.tscn"
	reinforcements_summoning=true
	OverworldGlobals.playSound("res://audio/sounds/12_human_jump_1.ogg")
	for combatant in getDeadCombatants('enemies'): 
		await replaceCombatant(combatant, enemy_reinforcements.pick_random().duplicate(), animation_path)
	for slot in range(getEmptySlots('enemies').size()):
		await addCombatant(enemy_reinforcements.pick_random().duplicate(),true,animation_path)
	
	reinforcements_summoning=false

func allCombatantsActed() -> bool:
	for combatant in getAllCombatants():
		if !combatant.acted: 
			return false
	
	return true

func getCombatantGroup(combatant:ResCombatant):
	var out = combatant_positions['team'] if combatant is ResPlayerCombatant else combatant_positions['enemies']
	out = out.filter(func(combatant): return combatant != null)
	return out 

func getEmptySlots(group:String):
	return combatant_positions[group].filter(func(spot): return spot == null)

func getCombatantPosition(combatant:ResCombatant):
	return combatant_positions['team'].find(combatant) if combatant is ResPlayerCombatant else combatant_positions['enemies'].find(combatant)

func isCombatantGroupDead(type: String):
	return getLivingCombatants(type).size() <= 0

func isCombatValid()-> bool:
	return !isCombatantGroupDead('team') and !isCombatantGroupDead('enemies') and combat_result != 2

func renameDuplicates():
	pass
#	var seen = []
#	for combatant in getAllCombatants():
#		if seen.has(combatant.name):
#			seen.append(combatant.name)
#			combatant.name = '%s %s' % [combatant.name, seen.count(combatant.name)]
#		else:
#			seen.append(combatant.name)

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
	while !combatant.status_effects.is_empty():
		combatant.status_effects[0].removeStatusEffect()

# This is disgusting but whatever
func tickStatusEffects(combatant: ResCombatant, tick_type: int):
	for i in range(combatant.status_effects.size()-1,-1,-1):
		var effect = combatant.status_effects[i]
		if effect.tick_type != tick_type and tick_type != -1: continue
		effect.tick()

#func refreshInstantCasts(combatant: ResCombatant):
#	for ability in combatant.ability_set:
#		if !ability.enabled and ability.instant_cast: ability.enabled = true

func moveTarget(target):
	var index = -1 #if target_combatant == null else valid_targets.find(target_combatant)
	if target_combatant == null:
		index = 0
	elif valid_targets is Array:
		index = valid_targets.find(target_combatant)
	elif valid_targets is ResCombatant:
		index = getAllCombatants().find(valid_targets)
	#elif target_combatant is ResCombatant:
	#	index = getAllCombatants().find(target_combatant)
	
	var targets_size = valid_targets.size()-1
	if target is ResCombatant and target.isDead(true): target = ''
	
	if selected_ability.target_type == ResAbility.TargetType.MULTI:
		target_combatant = valid_targets
	elif target is ResCombatant: #and getAllCombatants().has(target):
		target_combatant = target
	elif target == '':
		target_combatant = valid_targets[index] if valid_targets is Array else valid_targets
	elif target == 'left':
		target_combatant = valid_targets[min(index-1,targets_size)]
	elif target == 'right':
		target_combatant = valid_targets[index+1 if index+1 <= targets_size else 0]
	
	await get_tree().process_frame
	target_hovered.emit(target_combatant)
	shiftCamera(target_combatant[0] if target_combatant is Array else target_combatant)

func moveInspect(direction:String):
	var all_combatants = getOrderedCombatants()
	print(all_combatants)
	var targets_size = all_combatants.size()-1
	var index = 0 if inspect_combatant == null else all_combatants.find(inspect_combatant)
	
	if direction == 'left':
		inspect_combatant = all_combatants[min(index-1,targets_size)]
	elif direction == 'right':
		inspect_combatant = all_combatants[index+1 if index+1 <= targets_size else 0]
	
	inspectTarget(false)
	moveCamera(inspect_combatant.combatant_scene.global_position)
## Array of combatants ordered according to visual position
func getOrderedCombatants()-> Array[ResCombatant]:
	var all_combatants: Array[ResCombatant] = []
	var enemies = combatant_positions['enemies'].duplicate()
	var allies = combatant_positions['team'].duplicate()
	allies.reverse()
	all_combatants.append_array(allies)
	all_combatants.append_array(enemies)
	all_combatants = all_combatants.filter(func(combatant): return combatant != null)
	return all_combatants

func inspectTarget(move_cam:bool):
	if combat_ui.inspector.animator.is_playing():
		return
	
	if inspect_combatant == null and target_combatant is ResCombatant:
		inspect_combatant = target_combatant
	elif inspect_combatant == null and target_combatant is Array:
		inspect_combatant = target_combatant[0]
	if !combat_ui.inspector.visible:
		combat_ui.inspector.showInspector()
	combat_ui.inspector.setCombatant(inspect_combatant)
	if move_cam:
		setUIModulation(Color.TRANSPARENT,0.2)
		setCameraZoom(DEFAULT_ZOOM+Vector2(0.25,0.25))
		moveCamera(inspect_combatant.combatant_scene.global_position,0.1)
	fadeInAllCombatants()
	await get_tree().process_frame
	fadeOutUntargeted(true)

func releaseInspect():
#	if combat_ui.inspector.animator.is_playing():
#		return
	
	#combat_ui.showUI(false, false)
	fadeInAllCombatants()
	if combat_ui.inspector.visible:
		combat_ui.inspector.hideInspector()
	setUIModulation(Color.WHITE,0.2)
	shiftCamera(target_combatant[0] if target_combatant is Array else target_combatant)
	setCameraZoom(DEFAULT_ZOOM,0.1)
	#shiftCamera(target_combatant[0].combatant_scene.global_position if target_combatant is Array else target_combatant.combatant_scene.global_position)
	inspect_combatant = null

func isInspecting():
	return combat_ui.inspector.visible

func runAbility():
	#target_state = TargetState.NONE
	if run_once:
		executeAbility()
		#action_panel.hide()
		run_once = false

func concludeCombat(results: int):
	if combat_result != -1: return
	if !turn_timer.is_stopped(): stopTimer()
	targeting = false
	removeDeadCombatants(false)
	combat_result = results
	battle_music.stop()
	moveCamera(DEFAULT_CAM_POS)
	for combatant in getAllCombatants():
		#refreshInstantCasts(combatant)
		clearStatusEffects(combatant)
		setSignals(combatant,false)
		clearTempModifiers(combatant,'turns')
		combatant.tickTemporaryModifiers('battle')
		#combatant.clearStrain()
		active_combatant.resolve_dot_shield = false
		active_combatant.resolve_gate = true
		if combat_result == 0 or getDeadCombatants('team').size() > 0: 
			await get_tree().create_timer(0.25).timeout
		if (combat_result == 1 or combat_result == 2) and combatant.isOnBrink() and combatant is ResPlayerCombatant:
			CombatGlobals.calculateHealing(combatant, combatant.getMaxHealth()*0.1,false,false)
	#target_state = TargetState.NONE
	#target_index = 0
	var morale_bonus = 1
	var loot_bonus = 1
	var morale_before = 0
	var bonuses = []
	await get_tree().create_timer(1.0).timeout
	toggleUI(false)
	combat_ui.hideUI()
	if combat_result == 1:
		if round_count <= 4:
			morale_bonus += 0.25
			loot_bonus += 1
			bonuses.append('Swift Finish!')
		if CombatGlobals.tension == 8:
			loot_bonus += 1
			bonuses.append('Full Tension!')
		if CombatGlobals.tension == 0:
			morale_bonus += 0.25
			bonuses.append('Exhausted Tension!')
		reward_bank['experience'] *= morale_bonus
		for i in range(loot_bonus):
			var enemy = slain_enemies.pick_random()
			reward_bank['loot'] = CombatGlobals.combineDictionaries(reward_bank['loot'], enemy.getDrops())
		var bc_ui = load("res://scenes/user_interface/CombatResultScreen.tscn").instantiate()
		bc_ui.morale = morale_before
		bc_ui.reward_bank = reward_bank
		bc_ui.bonuses = bonuses
		add_child(bc_ui)
		await bc_ui.done
		bc_ui.queue_free()
	else:
		OverworldGlobals.playSound("res://audio/sounds/51_Flee_02.ogg")
	for combatant in combatant_positions['team']:
		if combatant == null: continue
		combatant.applyTalents()
	
	#transition_scene.visible = true
	#transition.play('In')
	#await transition.animation_finished
	
	combat_done.emit()
	
	var end_sentence = ''
	if combat_dialogue != null: 
		combat_dialogue.disconnectSignal()
		end_sentence = combat_dialogue.end_sentence
	CombatGlobals.tension = 0
	UIGlobals.setControllerAdapter(false)
	queue_free()

## NOTE: If do_reparent is false, the combatant scene will be reparented AFTER the moving action based on their current position.
#func changeCombatantPosition(combatant: ResCombatant, move: int, do_reparent: bool=true, move_count:int=1):
#	is_combatant_moving = true
#	var combatant_group
#	if combatant is ResPlayerCombatant:
#		combatant_group = team_container_markers
#	else:
#		combatant_group = enemy_container_markers
#	var current_pos = combatant_group.find(combatant.combatant_scene.get_parent())
#	if moveValid(move, current_pos, combatant_group) or move == 0:
#		for i in range(move_count): await moveCombatantPosition(combatant, combatant_group, move, do_reparent)
#
#	move_finished.emit()
#	is_combatant_moving = false

func moveCombatant(combatant: ResCombatant, direction: int, move_count:int):
	var group = 'enemies' if combatant is ResEnemyCombatant else 'team'
	var combatant_index = combatant_positions[group].find(combatant)
	#print('dihre: ', combatant_index+direction)
	#if combatant_index+direction > 3 or combatant_index+direction < 0: return
	for i in range(move_count):
		if combatant_index+direction > 3 or combatant_index+direction < 0: 
			continue
		await get_tree().process_frame
		var adjacent_combatant = combatant_positions[group][combatant_index+direction]
		if adjacent_combatant == null:
			combatant_positions[group][combatant_index+direction] = combatant
			combatant_positions[group][combatant_index] = null
		else:
			swapCombatantPosition(combatant, adjacent_combatant)
		combatant_index = combatant_positions[group].find(combatant)
	await get_tree().process_frame
	moveCombatantScenes(group, direction)
	#print(combatant_positions[group])

func swapCombatantPosition(combatant_a, combatant_b):
	var group = 'enemies' if combatant_a is ResEnemyCombatant else 'team'
	var combatant_index_a = combatant_positions[group].find(combatant_a)
	var combatant_index_b = combatant_positions[group].find(combatant_b)
	var temp_combatant_a = combatant_positions[group][combatant_index_a]
	combatant_positions[group][combatant_index_a] = combatant_positions[group][combatant_index_b]
	combatant_positions[group][combatant_index_b] = temp_combatant_a
	#combatant_positions[group][com]

func moveCombatantScenes(group: String, direction:int):
	is_combatant_moving = true
	for combatant in combatant_positions[group]:
		if combatant == null: continue
		var scene = combatant.combatant_scene
		if getRankPosition(combatant) == scene.global_position: continue
		
		var move_tween = CombatGlobals.getCombatScene().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
		move_tween.finished.connect(move_tween.kill)
		move_tween.tween_property(scene, 'global_position', getRankPosition(combatant),0.25)
		move_tween.tween_property(combatant.getSprite(), 'rotation', 0.2*direction,0.25)
		move_tween.set_parallel(false)
		move_tween.tween_property(combatant.getSprite(), 'rotation', 0,0.25)
		#await get_tree().create_timer(0.05).timeout
	
	move_finished.emit()

#func moveCombatantToEmpty(combatant):
#	var group = 'enemies' if combatant is ResEnemyCombatant else 'team'

func fadeCombatant(target: CombatantScene, fade_in: bool, duration: float=0.25):
	var tween = CombatGlobals.getCombatScene().create_tween()
	if fade_in:
		tween.tween_property(target.get_node('Sprite2D'), 'modulate', Color(Color.WHITE, 1.0), duration)
	else:
		tween.tween_property(target.get_node('Sprite2D'), 'modulate', Color(Color.WHITE, 0.0), duration)
	target.get_node('CombatBars').setBarVisibility(fade_in)
	await tween.finished

#func addTargetClickButton(combatant: ResCombatant):
#	return
#	if !is_instance_valid(combatant.combatant_scene): 
#		return
#	combatant.combatant_scene.get_node('CombatBars').enableClicker()

#func removeTargetButtons():
#	return
#	for combatant in combatants:
#		combatant.combatant_scene.get_node('CombatBars').disableClicker()

func startTimer():
	turn_timer_bar.process_mode = Node.PROCESS_MODE_INHERIT
	turn_timer.start(turn_time)
	turn_timer_animator.play("Show")

func stopTimer():
	#if turn_timer.time_left > turn_time*0.25:
	#	CombatGlobals.addTension(1)
	
	turn_timer_animator.play_backwards("Show")
	turn_timer.stop()
	#turn_timer_bar.process_mode = Node.PROCESS_MODE_DISABLED

func _on_turn_timer_timeout():
	turn_timer_animator.play_backwards("Show")
	confirm.emit()

func resetUI():
	moveCamera(DEFAULT_CAM_POS)
	targeting=false
	targeting_ended.emit()
#	removeTargetButtons()
	combat_ui.showUI()

func attemptEscape():
	if CombatGlobals.randomRoll(calculateEscapeChance()):
		combat_ui.hideUI()
		CombatGlobals.combat_lost.emit(unique_id)
		concludeCombat(2)
	else:
		combat_ui.hideUI()
		var previous_active = active_combatant
		bonus_escape_chance += 0.1
		OverworldGlobals.playSound("res://audio/sounds/033_Denied_03.ogg")
		if !usedInstantCastAbility(): selected_ability = null
		confirm.emit()
		CombatGlobals.addStatusEffect(previous_active, 'Stunned', true)

func setSignals(combatant:ResCombatant, connect_signals:bool):
	if connect_signals:
		if !combatant.player_turn.is_connected(on_player_turn):
			combatant.player_turn.connect(on_player_turn)
		if !combatant.enemy_turn.is_connected(on_enemy_turn):
			combatant.enemy_turn.connect(on_enemy_turn)
	else:
		if combatant.player_turn.is_connected(on_player_turn):
			combatant.player_turn.disconnect(on_player_turn)
		if combatant.enemy_turn.is_connected(on_enemy_turn):
			combatant.enemy_turn.disconnect(on_enemy_turn)

func clearTempModifiers(combatant: ResCombatant, type:String):
	for modifier in combatant.getTemporaryModifierKeys(type):
		combatant.removeTemporaryModifier(modifier)

func doRebuke(target: ResCombatant, caster: ResCombatant):
	var guard_effect:ResStatusEffect
	var base_rebuke_chance:float = target.stat_modifiers['base_rebuke']['rebuke_chance']
	rebuking=true
	
	# Heal ouchies
	CombatGlobals.healResolve(target,99)
	if target is ResPlayerCombatant:
		for injury in target.getTraitsWithFlag('injury'): target.removeTrait(injury)
	# Do riposte
	CombatGlobals.removeStatusEffect(target,'Guard Break')
	CombatGlobals.addStatusEffect(target,'Guard',true,{'bonus_duration':1})
	guard_effect=target.getStatusEffect('Guard')
	if caster != null:
		guard_effect.status_script.doRiposte(target,caster,guard_effect)
	else:
		moveCamera(target.combatant_scene.global_position,0)
	
	# Do visual effects
	target.combatant_scene.z_index = caster.combatant_scene.z_index+1
	toggleUI(false)
	OverworldGlobals.playSound("res://audio/sounds/744329__fairsonicstudio__bbrs_sfx_soulretrieve.ogg")
	OverworldGlobals.playSound(['165491__chripei__victory-cry-reverb-2.ogg', '165492__chripei__victory-cry-reverb-1.ogg'].pick_random())
	OverworldGlobals.playSound("res://audio/sounds/482686__jocmusic__war-horn-blast.ogg")
	setUIModulation(Color.TRANSPARENT)
	playRebukeText()
	await zoomCamera(Vector2(0.75,0.75),0.1)
	await OverworldGlobals.freezeFrame(0.075, 2.8)
	setUIModulation(Color.WHITE)
	CombatGlobals.calculatePercentHealing(target,1.0,false)
	target.addTemporaryModifer(
		'rebuke_penalty',
		1,
		{'rebuke_chance':-base_rebuke_chance/2},
		false,
		true,
		false
		)
	if combat_camera.zoom != DEFAULT_ZOOM:
		setCameraZoom(DEFAULT_ZOOM)
	if combat_camera.global_position != DEFAULT_CAM_POS:
		moveCamera(DEFAULT_CAM_POS)
	toggleUI(true)
	
	rebuking=false
	rebuke_finished.emit()
