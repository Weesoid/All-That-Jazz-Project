extends Node2D
class_name CombatScene

enum TargetState {
	NONE,
	SINGLE,
	MULTI,
	INSPECT
}

@export var combatants: Array[ResCombatant]
@onready var combat_camera = $CombatCamera
@onready var team_container_markers = $TeamContainer.get_children()
@onready var enemy_container_markers = $EnemyContainer.get_children()
@onready var onslaught_container = $OnslaughtContainer
@onready var onslaught_container_animator = $OnslaughtContainer/AnimationPlayer
@onready var transition_scene = $CombatCamera/BattleTransition
@onready var transition = $CombatCamera/BattleTransition.get_node('AnimationPlayer')
@onready var battle_music = $BattleMusic
@onready var battle_back = $ParallaxBackground/AnimationPlayer
@onready var team_hp_bar = $OnslaughtContainer/ProgressBar
@onready var turn_timer_bar = $CombatCamera/Interface/TurnTimerBar
@onready var turn_timer_animator = $CombatCamera/Interface/TurnTimerBar/AnimationPlayer
@onready var turn_timer = $TurnTimer
@onready var fade_bars_animator = $CombatCamera/FadeBars/AnimationPlayer
@onready var flasher = $CombatCamera/Flasher
@onready var flasher_animator = $CombatCamera/Flasher/AnimationPlayer
@onready var ui_inspect_target = $CombatCamera/Interface/Inspect
@onready var ui_attribute_view = $CombatCamera/Interface/Inspect/AttributeView
@onready var combat_ui: CombatUI = $CombatCamera/Interface/CombatUI
@onready var tp_particle_magnet = $TensionParticleMarker

var combatant_turn_order: Array
var combat_dialogue: CombatDialogue
var unique_id: String
var target_state: TargetState = TargetState.NONE # 0=None, 1=Single, 2=Multi
var active_combatant: ResCombatant
var valid_targets
var target_combatant
var target_index = 0
var combat_event: ResCombatEvent
var selected_ability: ResAbility
var run_once = true
var total_experience = 0
var turn_count = 0
var round_count = 0
var player_turn_count = 0
var enemy_turn_count = 0
var battle_music_path: String = ""
var combat_result: int = -1
var camera_position: Vector2 = Vector2(0, 5)
var enemy_reinforcements: Array[ResCombatant]
var bonus_escape_chance = 1.0
var onslaught_mode = false
var onslaught_combatant: ResPlayerCombatant
var previous_position: Vector2
var previous_position_player: Vector2
var tween_running
var can_escape
var do_reinforcements
var last_used_ability: Dictionary = {}
var ability_charge_tracker: Dictionary = {}
var turn_time: float = 0.0
var reinforcements_turn: int = 50
var is_combatant_moving = false
var initial_damage: float = 0.0
var combat_entity
var reward_bank

signal confirm
signal target_selected
signal update_exp(value: float, max_value: float)
signal move_finished
signal dialogue_done
signal combat_done

#********************************************************************************
# INITIALIZATION AND COMBAT LOOP
#********************************************************************************
#func _init(p_):
#	reward_bank = p_ #placeholder

func _ready():
	team_hp_bar.process_mode = Node.PROCESS_MODE_DISABLED
	if OverworldGlobals.getCurrentMap().has_node('Balloon'):
		OverworldGlobals.getCurrentMap().get_node('Balloon').queue_free()
	
	transition_scene.visible = true
	CombatGlobals.execute_ability.connect(commandExecuteAbility)
	renameDuplicates()
	
	battle_back.play('Show')
	transition.play('Out')
	await transition.animation_finished
	
	var dead_combatants = []
	for combatant in combatants:
		if combatant.isDead(): 
			dead_combatants.append(combatant)
			continue
		await addCombatant(combatant, false, '', true)
	for combatant in dead_combatants:
		combatants.erase(combatant)
	if battle_music_path != "":
		battle_music.stream = load(battle_music_path)
		battle_music.play()
	
	# ACTIVATE COMBAT START STATUSES!
	for combatant in combatants:
		tickStatusEffects(combatant, false, false, true)
		tickStatusEffects(combatant, true, false, true)

	if initial_damage > 0.0:
		for combatant in getCombatantGroup('enemies'):
			await get_tree().create_timer(0.05).timeout
			CombatGlobals.calculateRawDamage(combatant, combatant.getMaxHealth()*initial_damage)

	await removeDeadCombatants(false)

	rollTurns()
	setActiveCombatant(false)
	while active_combatant.isImmobilized():
		setActiveCombatant(false)


	active_combatant.act()
#	active_combatant.combatant_scene.get_node('CombatBars').pulse_gradient.play('Show')
	if combat_dialogue != null:
		combat_dialogue.initialize()

	transition_scene.visible = false
	OverworldGlobals.setMouseController(true)

	# Handle overworld stuff
	if combat_entity is GenericPatroller:
		reward_bank = combat_entity.patroller_group.reward_bank
	else:
		reward_bank = combat_entity.get_node('CombatantSquadComponent').reward_bank

	if OverworldGlobals.getCurrentMap().has_node('StalkerEngage'):
		OverworldGlobals.getCurrentMap().get_node('StalkerEngage').queue_free()
	if OverworldGlobals.getCurrentMap().has_node('Stalker'):
		OverworldGlobals.getCurrentMap().get_node('Stalker').modulate = Color.WHITE

	combat_ui.initialize()
	#await get_tree().process_frame
	#attemptEscape()
	print('full')
func _process(_delta):
	#print(combatant_turn_order)
	#$CombatCamera/Interface/Label.text = str(Engine.get_frames_per_second())
	#ui_attribute_view.combatant = target_combatant
	#round_counter.text = str(round_count)
	
	match target_state:
		TargetState.SINGLE: playerSelectSingleTarget()
		TargetState.MULTI: playerSelectMultiTarget()
		TargetState.INSPECT: playerSelectInspection()

func _unhandled_input(_event):
	if onslaught_mode and Input.is_action_just_pressed('ui_left') and !tween_running and onslaught_combatant != null and !onslaught_combatant.isDead():
		moveOnslaught(-1)
	if onslaught_mode and Input.is_action_just_pressed('ui_right') and !tween_running and onslaught_combatant != null and !onslaught_combatant.isDead():
		moveOnslaught(1)
	
	if (Input.is_action_just_pressed('ui_cancel') or Input.is_action_just_pressed("ui_show_menu")  or Input.is_action_just_pressed("ui_right_mouse")) and !onslaught_mode: 
		resetUI()
		
#	if Input.is_action_just_pressed('ui_home'):
#		if action_panel.visible == true:
#			toggleUI(false)
#		else:
#			toggleUI(true)
	if Input.is_action_pressed("ui_select_arrow") and !ui_inspect_target.visible and target_state == TargetState.SINGLE:
		inspectTarget(true)
	elif Input.is_action_just_released("ui_select_arrow") and target_state == TargetState.SINGLE:
		inspectTarget(false)

func on_player_turn():
	CombatGlobals.active_combatant_changed.emit(active_combatant)
	if active_combatant.ai_package != null:
		if has_node('QTE'): await CombatGlobals.qte_finished
		if await checkWin(): return
		await useAIPackage()
		return
	
	if has_node('QTE'):
		await CombatGlobals.qte_finished
		await get_node('QTE').tree_exited
	
	Input.action_release("ui_accept")
	moveCamera(camera_position)
	combat_ui.showAbilities(active_combatant)
	if turn_time > 0.0:
		startTimer()
	await confirm
	end_turn()

func on_enemy_turn():
	CombatGlobals.active_combatant_changed.emit(active_combatant)
	if has_node('QTE'): 
		await CombatGlobals.qte_finished
	if await checkWin(): 
		return
	combat_ui.hideUI()
	await useAIPackage()

func useAIPackage():
	selected_ability = active_combatant.ai_package.selectAbility(active_combatant.ability_set, active_combatant)
	if selected_ability != null:
		valid_targets = selected_ability.getValidTargets(sortCombatantsByPosition(), active_combatant is ResPlayerCombatant)
		if selected_ability.getTargetType() == 1 and selected_ability.target_group != 2:
			target_combatant = active_combatant.ai_package.selectTarget(valid_targets)
		else:
			target_combatant = valid_targets
		if target_combatant != null:
			if selected_ability.charges > 0: updateAbilityChargeTracker(active_combatant, selected_ability)
			executeAbility()
	else:
		showCannotAct('Pass!', true)
	
	await confirm
	end_turn()

func end_turn(combatant_act=true):
	if !turn_timer.is_stopped(): 
		stopTimer()
	if await checkWin(): 
		return
	if combatant_act and (selected_ability == null or !selected_ability.instant_cast):
		tickStatusEffects(active_combatant, false, true, false, false) # Tick down ON TURN statuses
	for combatant in combatants: # Check for survivors!
		if combatant.isDead(): continue
		CombatGlobals.dialogue_signal.emit(combatant)
	if combatant_act and (selected_ability == null or !selected_ability.instant_cast):
		active_combatant.turn_charges -= 1
		combatant_turn_order.remove_at(0)
		if active_combatant.turn_charges <= 0:
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
	
	if is_combatant_moving: # The "is_moving" sandwhich
		await get_tree().process_frame
		if is_combatant_moving: await move_finished
		await get_tree().process_frame
	
	if combat_event != null and turn_count % combat_event.turn_trigger == 0:
		combat_ui.writeCombatLog(combat_event.event_message)
		commandExecuteAbility(null, combat_event.ability)
		await get_tree().create_timer(2.0).timeout
		if await checkWin(): return
	elif combat_event != null and turn_count % combat_event.turn_trigger == combat_event.turn_trigger - 3:
		combat_ui.writeCombatLog(combat_event.warning_message)
	
	var turn_title = 'turn/%s' % turn_count
	CombatGlobals.dialogue_signal.emit(turn_title)
	
	for combatant in combatants:
		if combatant.isDead(): continue
		refreshInstantCasts(combatant)
		tickStatusEffects(combatant, true) # Tick PER TURN statuses (e.g. tick even tho its not the combatant's)
		CombatGlobals.dialogue_signal.emit(combatant)
	removeDeadCombatants()
	
	# Reset values
	run_once = true
	target_index = 0
	
	# REINFORCEMENTS
	randomize()
	if turn_count % (reinforcements_turn-1) == 0 and (getDeadCombatants('enemies').size() > 0 or getCombatantGroup('enemies').size() < 4) and isCombatValid() and do_reinforcements:
		combat_ui.writeCombatLog('Enemy reinforcements are incoming!')
	if turn_count % reinforcements_turn == 0 and (getDeadCombatants('enemies').size() > 0 or getCombatantGroup('enemies').size() < 4) and isCombatValid() and do_reinforcements:
		combat_ui.writeCombatLog('Enemy reinforcements arrived!')
		bonus_escape_chance -= 0.25
		var replace = []
		for combatant in combatants:
			if combatant.isDead() and combatant is ResEnemyCombatant: replace.append(combatant)
		for combatant in replace:
			var replacement: ResEnemyCombatant = enemy_reinforcements.pick_random().duplicate()
			replacement.drop_pool = {}
			await replaceCombatant(combatant, replacement, "res://scenes/animations_abilities/Reinforcements.tscn")
		if getCombatantGroup('enemies').size() < 4:
			var size = getCombatantGroup('enemies').size()
			for i in range(4 - size):
				var random: ResEnemyCombatant = enemy_reinforcements.pick_random().duplicate()
				await addCombatant(random, true, "res://scenes/animations_abilities/Reinforcements.tscn")
		
	# Determine next combatant
	if selected_ability == null or !selected_ability.instant_cast:
		if has_node('QTE'):
			await CombatGlobals.qte_finished
			await get_node('QTE').tree_exited
		setActiveCombatant()
	if selected_ability != null and selected_ability.isMutated():
		selected_ability.restoreProperties()
	
	if checkDialogue():
		await DialogueManager.dialogue_ended
	
	if !active_combatant.isImmobilized():
		active_combatant.removeTokens(ResStatusEffect.RemoveType.ON_TURN)
		active_combatant.act()
#		active_combatant.combatant_scene.get_node('CombatBars').pulse_gradient.play('Show')
	else:
		if is_instance_valid(active_combatant.combatant_scene):
			active_combatant.removeTokens(ResStatusEffect.RemoveType.ON_TURN)
			await showCannotAct('Immobile!')
		end_turn()
		return
	if await checkWin(): 
		return

func showCannotAct(message:String,emit_confirm:bool=false):
	moveCamera(active_combatant.combatant_scene.global_position)
	CombatGlobals.manual_call_indicator.emit(active_combatant, message, 'Show')
	await get_tree().create_timer(1.25).timeout
	if emit_confirm:
		confirm.emit()

func setActiveCombatant(tick_effect=true):
	active_combatant = combatant_turn_order[0][0]
	if tick_effect:
		tickStatusEffects(active_combatant, false, false, false) # Tick ON TURN statuses (e.g. tick only on combatant's turn)
		removeDeadCombatants()

func getTickOnTurnEffects(combatant: ResCombatant):
	var out = []
	for effect in combatant.status_effects:
		if !effect.tick_any_turn: out.append(effect)
	return out

func removeDeadCombatants(fading=true, is_valid_check=true):
	if !isCombatValid() and is_valid_check: return
	
	for combatant in getDeadCombatants():
		combatant.removeTokens(ResStatusEffect.RemoveType.ON_TURN)
		if combatant is ResEnemyCombatant:
			if !combatant.getStatusEffectNames().has('Knock Out'): 
				clearStatusEffects(combatant)
				CombatGlobals.addStatusEffect(combatant, 'KnockOut')
				combatant.acted = true
				if combatant.combatant_scene.has_node('CombatBars'):
					combatant.combatant_scene.get_node('CombatBars').hide()
				total_experience += combatant.getExperience()
			if combatant.spawn_on_death != null:
				replaceCombatant(combatant, combatant.spawn_on_death) ## Also keeping this!
		elif combatant is ResPlayerCombatant:
			if !combatant.hasStatusEffect('Fading') and !combatant.hasStatusEffect('Knock Out') and fading: 
				clearStatusEffects(combatant)
				if (combatant.hasStatusEffect('Faded IV') and CombatGlobals.randomRoll(0.5)):
					CombatGlobals.addStatusEffect(combatant, 'Fading')
				elif combatant.hasStatusEffect('Faded IV'):
					CombatGlobals.addStatusEffect(combatant, 'KnockOut')
					combatant.acted = true
				else:
					CombatGlobals.addStatusEffect(combatant, 'Fading')
			elif !combatant.getStatusEffectNames().has('Knock Out') and !fading:
				CombatGlobals.addStatusEffect(combatant, 'KnockOut')
				combatant.acted = true
				if combatant.combatant_scene.has_node('CombatBars'):
					combatant.combatant_scene.get_node('CombatBars').hide()
			if !fading:
				await get_tree().create_timer(0.25).timeout
#********************************************************************************
# BASE combatant_scene NODE CONTROL
#********************************************************************************
func calculateEscapeChance()-> float:
	var hustle_enemies = 0
	var hustle_allies = 0
	for combatant in getCombatantGroup('enemies'):
		hustle_enemies += combatant.base_stat_values['speed']
	for combatant in getCombatantGroup('team'):
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
	for marker in enemy_container_markers:
		if marker.get_child_count() != 0 and marker.get_child(0).combatant_scene.has_node('CombatBars'):
			create_tween().tween_property(marker.get_child(0).get_node('CombatBars'), 'modulate', ui_modulate, duration)
	for marker in team_container_markers:
		if marker.get_child_count() != 0 and marker.get_child(0).combatant_scene.has_node('CombatBars'):
			create_tween().tween_property(marker.get_child(0).get_node('CombatBars'), 'modulate', ui_modulate, duration)
	
	for child in combat_camera.get_children():
		if child is Control:
			create_tween().tween_property(child, 'modulate', ui_modulate, duration)

#********************************************************************************
# ability SELECTION, TARGETING, AND EXECUTION
#********************************************************************************
func playerSelectSingleTarget():
	if getCombatantGroup('enemies').is_empty() or (valid_targets is Array and valid_targets.is_empty()):
		return
	
	if valid_targets is Array:
		target_combatant = valid_targets[target_index]
	else:
		target_combatant = valid_targets
	moveCamera(target_combatant.combatant_scene.global_position)
	browseTargetsInputs()
	confirmCancelInputs()

func playerSelectMultiTarget():
	if getCombatantGroup('enemies').is_empty():
		return
	
	target_combatant = selected_ability.getValidTargets(combatants, true)
	confirmCancelInputs()

func playerSelectInspection():
	valid_targets = sortCombatantsByPosition()
	target_combatant = valid_targets[target_index]
	ui_inspect_target.show()
	ui_attribute_view.combatant = target_combatant
	
	moveCamera(target_combatant.combatant_scene.global_position)
	browseTargetsInputs()
	confirmCancelInputs()

func inspectTarget(inspect:bool):
	if !target_combatant is ResCombatant: return
	
	ui_attribute_view.combatant = target_combatant
	if inspect:
		ui_inspect_target.show()
		zoomCamera(Vector2(0.25,0.25))
	else:
		zoomCamera(Vector2(-0.25,-0.25))
		ui_inspect_target.hide()

func removeTargetToken(target, caster):
	if !CombatGlobals.isSameCombatantType(target,caster):
		target_combatant.removeTokens(ResStatusEffect.RemoveType.GET_TARGETED)

func executeAbility():
	if !turn_timer.is_stopped(): 
		stopTimer()
	active_combatant.combatant_scene.z_index = 100
	for combatant in combatants:
		if target_combatant is ResCombatant and ((target_combatant != combatant and active_combatant != combatant) or (target_combatant is Array and !target_combatant.has(combatant) and active_combatant != combatant)):
			CombatGlobals.setCombatantVisibility(combatant.combatant_scene, false)
	if target_combatant is ResPlayerCombatant:
		allowBlocking(target_combatant)
	elif target_combatant is Array:
		for target in target_combatant: 
			allowBlocking(target)
	
	if active_combatant is ResPlayerCombatant:
		CombatGlobals.addTension(-selected_ability.tension_cost)
	last_used_ability[active_combatant] = [selected_ability, target_combatant]
	
	await get_tree().create_timer(0.25).timeout
	if target_combatant is ResCombatant:
		selected_ability.ability_script.animate(active_combatant.combatant_scene, target_combatant.combatant_scene, selected_ability)
	else:
		selected_ability.ability_script.animate(active_combatant.combatant_scene, target_combatant, selected_ability)
	if selected_ability.target_type == ResAbility.TargetType.SINGLE and !selected_ability.isOnslaught():
		moveCamera(target_combatant.combatant_scene.global_position)
	elif selected_ability.target_type == ResAbility.TargetType.SINGLE and selected_ability.isOnslaught():
		moveCamera(camera_position)
	elif selected_ability.target_type == ResAbility.TargetType.MULTI:
		moveCamera(target_combatant[0].combatant_scene.global_position)
	CombatGlobals.ability_casted.emit(selected_ability)
	await CombatGlobals.ability_finished
	if has_node('QTE'):
		await CombatGlobals.qte_finished
		await get_node('QTE').tree_exited
	Input.action_release("ui_accept")
	for combatant in combatants:
		CombatGlobals.setCombatantVisibility(combatant.combatant_scene, true)
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

func allowBlocking(target: ResCombatant):
	if target is ResPlayerCombatant and target.combatant_scene.blocking and active_combatant is ResEnemyCombatant:
		target.combatant_scene.allow_block = true
		CombatGlobals.showWarning(target.combatant_scene)

func revokeBlocking(target: ResCombatant):
	if target is ResPlayerCombatant and target.combatant_scene.blocking and active_combatant is ResEnemyCombatant:
		target.combatant_scene.allow_block = false

func skipTurn():
	target_state = TargetState.NONE
	if run_once:
		Input.action_release("ui_accept")
		confirm.emit()
		#combat_ui.hideUI()
		#action_panel.hide()
		run_once = false

# For executing combat events and such.
func commandExecuteAbility(target, ability: ResAbility):
	if ability.target_type == ResAbility.TargetType.MULTI:
		target = ability.getValidTargets(combatants, active_combatant is ResPlayerCombatant)
	if ability.isBasicAbility():
		ability.ability_script.animate(null, target, ability)
	ability.ability_script.applyEffects(null, target, ability)
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

func addCombatant(combatant:ResCombatant, spawned:bool=false, animation_path:String='', do_tween:bool=false):
	if !isCombatValid(): #getCombatantGroup('enemies').size() == 4: 
		return
	var team_container
	combatant.initializeCombatant()
	setSignals(combatant,true)
	if combatant is ResPlayerCombatant:
		team_container = team_container_markers
	else:
		team_container = enemy_container_markers
	if do_tween:
		if combatant is ResPlayerCombatant:
			combatant.combatant_scene.global_position = Vector2(-100, 0)
		else:
			combatant.combatant_scene.global_position = Vector2(100, 0)
	if combatant is ResEnemyCombatant and combatant.is_converted:
		combatant.combatant_scene.rotation_degrees = -180
		combatant.combatant_scene.get_node('Sprite2D').flip_v = true
#		combat_bars.rotation_degrees = 180
	if spawned:
		combatants.append(combatant)
		combatant.acted = false
		combatant.turn_charges = combatant.max_turn_charges
		for turn_charge in range(combatant.max_turn_charges):
			var rolled_speed = randi_range(1, 8) + combatant.stat_values['speed']
			combatant_turn_order.append([combatant, rolled_speed])
	for marker in team_container:
		if marker.get_child_count() != 0: continue
		marker.add_child(combatant.combatant_scene)
#		var combat_bars = load("res://scenes/user_interface/CombatBars.tscn").instantiate()
#		combat_bars.attached_combatant = combatant
#		combatant.combatant_scene.add_child(combat_bars)
#		combatant.combatant_scene.get_node('CombatBars').attached_combatant = combatant
#		combatant.combatant_scene.get_node('CombatBars').show()
		break
	if combatant is ResPlayerCombatant and combatant.isDead():
		combatant.combatant_scene.doAnimation('Fading')
	else:
		combatant.combatant_scene.doAnimation('Idle')
	if animation_path != '':
		await CombatGlobals.playAbilityAnimation(combatant, load(animation_path), 0.15)
	if do_tween:
		var tween = create_tween().tween_property(combatant.combatant_scene, 'global_position', combatant.combatant_scene.get_parent().global_position, 0.15)
		await tween.finished
		OverworldGlobals.playSound("res://audio/sounds/220190__gameaudio__blip-pop.ogg")
	
	combatant.startBreatheTween(true)

func replaceCombatant(combatant: ResCombatant, new_combatant: ResCombatant, animation_path:String=''):
	combatants.erase(combatant)
	combatant_turn_order.erase(combatant)
	await get_tree().create_timer(0.25).timeout
	combatant.combatant_scene.queue_free()
	await combatant.combatant_scene.tree_exited
	addCombatant(new_combatant, true)
	if animation_path != '':
		await CombatGlobals.playAbilityAnimation(new_combatant, load(animation_path), 0.15)
#	escape_button.disabled = true
	#writeCombatLog("The grasp of the void prevents your escape.")

func removeCombatant(combatant: ResCombatant):
	combatant.combatant_scene.get_parent().get_node('CombatBars').hide()
	setSignals(combatant,false)
	combatants.erase(combatant)
	combatant_turn_order.erase(combatant)
	combatant.combatant_scene.queue_free()

# Cast Ability for players
func forceCastAbility(ability: ResAbility, weapon: ResWeapon=null):
	selected_ability = ability
	valid_targets = selected_ability.getValidTargets(sortCombatantsByPosition(), true)
	if ability.target_type == ResAbility.TargetType.MULTI:
		addTargetClickButton(active_combatant)
	elif valid_targets is Array:
		for target in valid_targets: addTargetClickButton(target)
	else:
		addTargetClickButton(valid_targets)
	target_state = selected_ability.getTargetType()
	if last_used_ability.keys().has(active_combatant) and last_used_ability[active_combatant][0] == ability and ability.target_type == ability.TargetType.SINGLE:
		targetCombatant(last_used_ability[active_combatant][1])
	await target_selected
	runAbility()
	if weapon != null: 
		weapon.useDurability()
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
	
	#secondary_description.show()

func getDeadCombatants(type: String=''):
	var dead_combatants = combatants.duplicate()
	if type == 'enemies':
		dead_combatants = dead_combatants.filter(func(combatant): return combatant is ResEnemyCombatant)
	elif type == 'team':
		dead_combatants = dead_combatants.filter(func(combatant): return combatant is ResPlayerCombatant)
	return dead_combatants.filter(func getDead(combatant): return combatant.isDead())

func targetCombatant(combatant: ResCombatant):
	if !combatants.has(combatant) or combatant.isDead():
		return
	
	if valid_targets is Array:
		target_index = valid_targets.find(combatant)
	else:
		target_index = combatant

func addDropToBank(loot_drops: Dictionary):
	for loot in loot_drops.keys():
		if reward_bank['loot'].has(loot):
			reward_bank['loot'][loot] += loot_drops[loot]
		else:
			reward_bank['loot'][loot] = loot_drops[loot]

func rollTurns():
	OverworldGlobals.playSound("714571__matrixxx__reverse-time.ogg")
	combatant_turn_order.clear()
	for combatant in combatants:
		if combatant.isDead() and !combatant.hasStatusEffect('Fading'): continue
		randomize()
		combatant.acted = false
		combatant.turn_charges = combatant.max_turn_charges
		for turn_charge in range(combatant.max_turn_charges):
			var rolled_speed = randi_range(1, 8) + combatant.stat_values['speed']
			combatant_turn_order.append([combatant, rolled_speed])
	combatant_turn_order.sort_custom(func(a, b): return a[1] > b[1])
	round_count += 1
	combat_ui.updateRoundCounter(round_count)
	#round_arrow_spinner.play("Spin")

func allCombatantsActed() -> bool:
	for combatant in combatants:
		if !combatant.acted: 
			return false
	
	return true

func getCombatantFromTurnOrder(combatant: ResCombatant)-> ResCombatant:
	for data in combatant_turn_order:
		if data[0] == combatant: return combatant
	
	return null

## 'team' or 'enemies'
func getCombatantGroup(type: String)-> Array[ResCombatant]:
	match type:
		'team': return combatants.duplicate().filter(func getTeam(combatant): return combatant is ResPlayerCombatant)
		'enemies': return combatants.duplicate().filter(func getEnemies(combatant): return combatant is ResEnemyCombatant)
	
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
	return combatants.duplicate().filter(func(combatant: ResCombatant): return !combatant.isDead())

func renameDuplicates():
	var seen = []
	for combatant in combatants:
		if seen.has(combatant.name):
			seen.append(combatant.name)
			combatant.name = '%s %s' % [combatant.name, seen.count(combatant.name)]
		else:
			seen.append(combatant.name)

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
	var effects = combatant.status_effects.filter(func(effect: ResStatusEffect):return !effect.persist_on_dead)
	if ignore_faded:
		effects.filter(func(effect: ResStatusEffect):return !effect.name.contains('Faded'))
		while !effects.is_empty():
			effects[0].removeStatusEffect()
			effects.remove_at(0)
	else:
		while !combatant.status_effects.is_empty():
			combatant.status_effects[0].removeStatusEffect()

# This is disgusting but whatever
func tickStatusEffects(combatant: ResCombatant, per_turn = false, update_duration=true, only_permanent=false, do_tick=true):
	for i in range(combatant.status_effects.size()-1,-1,-1):
		var effect = combatant.status_effects[i]
		if only_permanent and !effect.permanent:
			continue
		if (per_turn and !effect.tick_any_turn) or (!per_turn and effect.tick_any_turn): 
			continue
		effect.tick(update_duration, false, do_tick)
		if effect.name == 'Fading' and update_duration: 
			CombatGlobals.manual_call_indicator.emit(combatant, SettingsGlobals.ui_colors['down-bb']+effect.getMessageIcon()+' ...!', 'Resist')

func refreshInstantCasts(combatant: ResCombatant):
	for ability in combatant.ability_set:
		if !ability.enabled and ability.instant_cast: ability.enabled = true

func incrementIndex(index:int, increment: int, limit: int):
	return (index + increment) % limit

func browseTargetsInputs():
	if !valid_targets is Array or Input.is_action_pressed('ui_select_arrow'):
		return
	
	if Input.is_action_just_pressed("ui_right"):
		OverworldGlobals.playSound("342694__spacejoe__lock-2-remove-key-2.ogg")
		target_index = incrementIndex(target_index, 1, valid_targets.size())
	if Input.is_action_just_pressed("ui_left"):
		OverworldGlobals.playSound("342694__spacejoe__lock-2-remove-key-2.ogg")
		target_index = incrementIndex(target_index, -1, valid_targets.size())

func confirmCancelInputs():
	if Input.is_action_pressed('ui_select_arrow'):
		return
	
	if Input.is_action_just_pressed("ui_accept") and target_state != 3:
		removeTargetButtons()
		OverworldGlobals.playSound("56243__qk__latch_01.ogg")
		target_selected.emit()
	if Input.is_action_just_pressed("ui_tab") or Input.is_action_just_pressed("ui_right_mouse") or Input.is_action_just_pressed("ui_cancel"):
		removeTargetButtons()
		#description_panel.hide()
		#ui_animator.play_backwards('FocusDescription')
		#resetActionLog()

func runAbility():
	target_state = TargetState.NONE
	if run_once:
		executeAbility()
		#action_panel.hide()
		run_once = false

func concludeCombat(results: int):
	if combat_result != -1: return
	if !turn_timer.is_stopped(): stopTimer()
	removeDeadCombatants(true, false)
	combat_result = results
	battle_music.stop()
	moveCamera(camera_position)
	for combatant in combatants:
		refreshInstantCasts(combatant)
		clearStatusEffects(combatant, false)
		setSignals(combatant,false)
		if combat_result == 0 or getDeadCombatants('team').size() > 0: 
			await get_tree().create_timer(0.25).timeout
	target_state = TargetState.NONE
	target_index = 0
	var morale_bonus = 1
	var loot_bonus = 1
	var morale_before = 0
	var drops = {}
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
		reward_bank['experience'] += total_experience * morale_bonus
		for enemy in getCombatantGroup('enemies'):
			var enemy_drops = enemy.getDrops()
			var barter_drops = enemy.getBarterDrops()
			enemy_drops.merge(barter_drops)
			addDropToBank(enemy_drops)
			drops.merge(enemy_drops)
		if loot_bonus > 1:
			for i in range(loot_bonus):
					for enemy in getCombatantGroup('enemies'):
						var enemy_drops = enemy.getDrops()
						addDropToBank(enemy_drops)
						drops.merge(enemy_drops)
		var bc_ui = load("res://scenes/user_interface/CombatResultScreen.tscn").instantiate()
		bc_ui.morale = morale_before
		bc_ui.drops = drops
		bc_ui.reward_bank = reward_bank
		bc_ui.bonuses = bonuses
		add_child(bc_ui)
		await bc_ui.done
		bc_ui.queue_free()
	else:
		OverworldGlobals.playSound("res://audio/sounds/51_Flee_02.ogg")
	
	transition_scene.visible = true
	transition.play('In')
	await transition.animation_finished
	
	combat_done.emit()
	
	var end_sentence = ''
	if combat_dialogue != null: 
		combat_dialogue.disconnectSignal()
		end_sentence = combat_dialogue.end_sentence
	CombatGlobals.tension = 0
	OverworldGlobals.setMouseController(false)
	queue_free()

## NOTE: If do_reparent is false, the combatant scene will be reparented AFTER the moving action based on their current position.
func changeCombatantPosition(combatant: ResCombatant, move: int, do_reparent: bool=true, move_count:int=1):
	is_combatant_moving = true
	var combatant_group
	if combatant is ResPlayerCombatant:
		combatant_group = team_container_markers
	else:
		combatant_group = enemy_container_markers
	var current_pos = combatant_group.find(combatant.combatant_scene.get_parent())
	if moveValid(move, current_pos, combatant_group) or move == 0:
		for i in range(move_count): await moveCombatantPosition(combatant, combatant_group, move, do_reparent)
	
	move_finished.emit()
	is_combatant_moving = false

func moveCombatantPosition(combatant: ResCombatant, combatant_group, move: int, do_reparent:bool):
	var current_pos = combatant_group.find(combatant.combatant_scene.get_parent())
	if !moveValid(move, current_pos, combatant_group): return
	var combatant_prev_pos = combatant.combatant_scene.global_position
	var tween_a = CombatGlobals.getCombatScene().create_tween().set_trans(Tween.TRANS_SINE)
	var tween_a_rotation = CombatGlobals.getCombatScene().create_tween().set_trans(Tween.TRANS_SINE) # ROTAT
	var tween_b
	var combatant_b
	var move_combatant_b_pos = move * -1
	if combatant_group[current_pos+move_combatant_b_pos].get_child_count() > 0:
		combatant_b = combatant_group[current_pos+move_combatant_b_pos].get_child(0)
	else:
		combatant_b = combatant_group[current_pos+move_combatant_b_pos]
	if combatant_b == null: 
		combatant_b = combatant_group[current_pos+move_combatant_b_pos]
#	killBreatheTweens(combatant)
#	if combatant_b != null:
#		killBreatheTweens(combatant_b.combatant_resource)
	
	tween_a.tween_property(combatant.combatant_scene, 'global_position', combatant_b.global_position, 0.18)
	tween_a_rotation.tween_property(combatant.combatant_scene.get_node('Sprite2D'), 'rotation', 0.25, 0.15)
	tween_a_rotation.tween_property(combatant.combatant_scene.get_node('Sprite2D'), 'rotation', 0, 0.15)
	if do_reparent: combatant.combatant_scene.reparent(combatant_group[current_pos+move_combatant_b_pos])
	
	if combatant_b is CombatantScene:
		tween_b = CombatGlobals.getCombatScene().create_tween().set_trans(Tween.TRANS_CUBIC)
		var tween_b_rotation = CombatGlobals.getCombatScene().create_tween().set_trans(Tween.TRANS_CUBIC)
		tween_b.tween_property(combatant_b, 'global_position', combatant_prev_pos, 0.2)
		tween_b_rotation.tween_property(combatant_b.get_node('Sprite2D'), 'rotation', -0.25, 0.15)
		if do_reparent: combatant_b.reparent(combatant_group[current_pos])
		tween_b_rotation.tween_property(combatant_b.get_node('Sprite2D'), 'rotation', 0, 0.15)
	
	if !do_reparent:
		if tween_a.is_running():
			await tween_a.finished
		if tween_b != null and tween_b.is_running():
			await tween_b.finished
		await get_tree().process_frame
		combatant.combatant_scene.reparent(combatant_group[current_pos+move_combatant_b_pos])
		combatant.startBreatheTween(true)
		if combatant_b is CombatantScene: 
			combatant_b.reparent(combatant_group[current_pos])
			combatant_b.combatant_resource.startBreatheTween(true)
	else:
		if tween_a.is_running():
			await tween_a.finished
		if tween_b != null and tween_b.is_running():
			await tween_b.finished
			combatant_b.combatant_resource.startBreatheTween(false)
		combatant.startBreatheTween(false)

#func killBreatheTweens(combatant: ResCombatant):
#	if combatant.pos_tween != null:
#		combatant.pos_tween.kill()
#	if combatant.scale_tween != null:
#		combatant.scale_tween.kill()

func moveValid(move:int, current_pos:int, combatant_group)-> bool:
	return (move == 1 and current_pos-1 >= 0) or (move == -1 and current_pos+1 <= combatant_group.size()-1)

#func getTamedCombatantsNames():
#	var out = []
#	for combatant in tamed_combatants: out.append(combatant)
#	return out

func moveOnslaught(direction: int):
	if (direction==1 and onslaught_combatant.combatant_scene.global_position.x+32 > 48) or (direction==-1 and onslaught_combatant.combatant_scene.global_position.x-32 < -48):
		return
	else:
		randomize()
		OverworldGlobals.playSound("res://audio/sounds/12_human_jump_%s.ogg" % str(randi_range(1,3)))
	tween_running = true
	var pos_tween = create_tween().set_trans(Tween.TRANS_BOUNCE)
	var move = 32 * direction
	pos_tween.tween_property(onslaught_combatant.combatant_scene, 'global_position', onslaught_combatant.combatant_scene.global_position+Vector2(move, 0), 0.1)
	await pos_tween.finished
	tween_running = false

func setOnslaught(combatant: ResPlayerCombatant, set_to:bool):
	await get_tree().process_frame
	active_combatant.combatant_scene.get_node('CombatBars').visible = false
	await fadeCombatant(active_combatant.combatant_scene, false)
	if !combatant.hasStatusEffect('Guard'):
		combatant.combatant_scene.setBlocking(set_to)
		combatant.combatant_scene.allow_block = set_to
	
	for target in combatants:
		if !target.hasStatusEffect('Knock Out') and target != combatant:
			target.combatant_scene.collision.disabled = set_to
	if set_to:
		team_hp_bar.process_mode = Node.PROCESS_MODE_INHERIT
		onslaught_container.show()
		onslaught_container_animator.play("Show")
		previous_position = active_combatant.combatant_scene.get_parent().global_position
		previous_position_player = combatant.combatant_scene.get_parent().global_position
		active_combatant.combatant_scene.get_parent().global_position = Vector2(0, -16)
		onslaught_combatant = combatant
		var tween = CombatGlobals.getCombatScene().create_tween()
		tween.tween_property(combatant.combatant_scene, 'global_position', onslaught_container.get_children()[0].global_position, 0.25)
		await tween.finished
		CombatGlobals.getCombatScene().zoomCamera(Vector2(0.5,0.5))
	else:
		team_hp_bar.process_mode = Node.PROCESS_MODE_DISABLED
		onslaught_container_animator.play_backwards("Show")
		onslaught_combatant = null
		active_combatant.combatant_scene.get_parent().global_position = previous_position
		combatant.combatant_scene.get_parent().global_position = previous_position_player
		active_combatant.combatant_scene.get_node('CombatBars').visible = true
		active_combatant.combatant_scene.moveTo(active_combatant.combatant_scene.get_parent())
		await combatant.combatant_scene.moveTo(combatant.combatant_scene.get_parent())
		onslaught_container.hide()
		CombatGlobals.getCombatScene().zoomCamera(Vector2(-0.5,-0.5))
	
	onslaught_mode = set_to
	await get_tree().process_frame

func fadeCombatant(target: CombatantScene, fade_in: bool, duration: float=0.25):
	var tween = CombatGlobals.getCombatScene().create_tween()
	if fade_in:
		tween.tween_property(target.get_node('Sprite2D'), 'modulate', Color(Color.WHITE, 1.0), duration)
	else:
		tween.tween_property(target.get_node('Sprite2D'), 'modulate', Color(Color.WHITE, 0.0), duration)
	target.get_node('CombatBars').setBarVisibility(fade_in)
	await tween.finished

func getCombatantPosition(combatant: ResCombatant=active_combatant)->int:
	if !is_instance_valid(combatant.combatant_scene):
		return 5
	
	if combatant is ResPlayerCombatant:
		return team_container_markers.find(combatant.combatant_scene.get_parent())
	else:
		return enemy_container_markers.find(combatant.combatant_scene.get_parent())

func sortCombatantsByPosition()-> Array[ResCombatant]:
	var out: Array[ResCombatant] = []
	var reversed_array = team_container_markers.duplicate()
	reversed_array.reverse()
	for combatant in reversed_array:
		if combatant.get_child_count() == 0: continue
		out.append(combatant.get_child(0).combatant_resource) # Might be a problem after replacing
	for combatant in enemy_container_markers:
		if combatant.get_child_count() == 0: continue
		out.append(combatant.get_child(0).combatant_resource) # Might be a problem after replacing
	return out

func addTargetClickButton(combatant: ResCombatant):
	return
#	if !is_instance_valid(combatant.combatant_scene): 
#		return
#	combatant.combatant_scene.get_node('CombatBars').enableClicker()

func removeTargetButtons():
	return
#	for combatant in combatants:
#		combatant.combatant_scene.get_node('CombatBars').disableClicker()

func startTimer():
	turn_timer_bar.process_mode = Node.PROCESS_MODE_INHERIT
	turn_timer.start(turn_time)
	turn_timer_animator.play("Show")

func stopTimer():
	if turn_timer.time_left > turn_time*0.25:
		CombatGlobals.addTension(1)
	
	turn_timer_animator.play_backwards("Show")
	turn_timer.stop()
	#turn_timer_bar.process_mode = Node.PROCESS_MODE_DISABLED

func _on_turn_timer_timeout():
	#resetActionLog()
	turn_timer_animator.play_backwards("Show")
	confirm.emit()

func battleFlash(animation: String, color: Color):
	flasher.modulate = color
	flasher_animator.play(animation)

func resetUI():
	moveCamera(camera_position)
	removeTargetButtons()
	combat_ui.showUI(true)
	target_state = TargetState.NONE
	target_index = 0

func attemptEscape():
	if CombatGlobals.randomRoll(calculateEscapeChance()):
		combat_ui.hideUI()
		CombatGlobals.combat_lost.emit(unique_id)
		concludeCombat(2)
	else:
		combat_ui.hideUI()
		var previous_active = active_combatant
		if !previous_active.hasStatusEffect('Poised'):
			battleFlash('Flash', Color.YELLOW)
		bonus_escape_chance += 0.1
		OverworldGlobals.playSound("res://audio/sounds/033_Denied_03.ogg")
		if selected_ability != null and selected_ability.instant_cast: selected_ability = null
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
