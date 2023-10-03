extends Node2D
class_name CombatScene

@export var COMBATANTS: Array[ResCombatant]

@onready var combat_camera = $CombatCamera
@onready var combat_log = $CombatCamera/LogContainer
@onready var enemy_container = $EnemyContainer
@onready var team_container_markers = $TeamContainer.get_children()
@onready var enemy_container_markers = $EnemyContainer.get_children()
@onready var secondary_panel = $CombatCamera/SecondaryPanel
@onready var secondary_panel_container = $CombatCamera/SecondaryPanel/Scroller/Container
@onready var action_panel = $CombatCamera/ActionPanel
@onready var attack_button = $CombatCamera/ActionPanel/Attack
@onready var equip_button = $CombatCamera/ActionPanel/Equipment
@onready var escape_button = $CombatCamera/ActionPanel/Escape
@onready var ui_target = $Target
@onready var ui_target_animator = $Target/TargetAnimator
@onready var ui_inspect_target = $CombatInspectTarget
@onready var turn_counter = $CombatCamera/Label

var combat_dialogue: ResCombatDialogue
var conclusion_dialogue: DialogueResource

var unique_id: String
var target_state = 0 # 0=None, 1=Single, 2=Multi
var active_combatant: ResCombatant
var active_index = 0
var valid_targets
var target_combatant
var target_index = 0
var selected_ability: ResAbility
var selected_item: ResConsumable
var run_once = true
var experience_earnt = 0
var drop_summary = ''
var turn_count = 0

signal confirm
signal target_selected
signal update_exp(value: float, max_value: float)
signal dialogue_done
signal combat_done

#********************************************************************************
# INITIALIZATION AND COMBAT LOOP
#********************************************************************************
func _ready():
	connectPlayerItems()
	CombatGlobals.execute_ability.connect(commandExecuteAbility)
	
	for combatant in COMBATANTS:
		spawnTroop(combatant)
		combatant.initializeCombatant()
		combatant.player_turn.connect(on_player_turn)
		combatant.enemy_turn.connect(on_enemy_turn)
	
		if combatant is ResPlayerCombatant:
			addCombatant(combatant, team_container_markers)
			connectPlayerAbilities(combatant)
		else:
			addCombatant(combatant, enemy_container_markers)
		
		var combat_bars = preload("res://scenes/user_interface/CombatBars.tscn").instantiate()
		combat_bars.attached_combatant = combatant
		combat_bars.global_position = combatant.SCENE.global_position - Vector2(110, -80)
		add_child(combat_bars)
	
	COMBATANTS.sort_custom(sortBySpeed)
	
	active_combatant = COMBATANTS[active_index]
	active_combatant.act()
	
	for combatant in COMBATANTS:
		tickStatusEffects(combatant)
	
	if combat_dialogue != null:
		combat_dialogue.initializeDialogue(COMBATANTS)
	
	ui_inspect_target.get_node('AnimationPlayer').play('Loop')
	# TO-DO: Battle Transition

func _process(_delta):
	turn_counter.text = str(turn_count)
	match target_state:
		1: playerSelectSingleTarget()
		2: playerSelectMultiTarget()
		3: playerSelectInspection()

func _unhandled_input(_event):
	if Input.is_action_just_pressed('ui_cancel') and secondary_panel.visible:
		resetActionLog()
	# Debug? Feature?
	if Input.is_action_just_pressed('ui_home'):
		toggleUI()

func on_player_turn():
	resetActionLog()
	action_panel.show()
	attack_button.grab_focus()
	
	await confirm
	end_turn()

func on_enemy_turn():
	if getCombatantGroup('team').is_empty():
		return
	
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

func end_turn():
	turn_count += 1
	CombatGlobals.turn_increment.emit(turn_count)
	combat_camera.position = Vector2(0, -19)
	for combatant in COMBATANTS:
		refreshInstantCasts(combatant)
		tickStatusEffects(combatant, true)
		CombatGlobals.combatant_stats.emit(combatant)
	
	for combatant in getDeadCombatants():
		combatant.getAnimator().play('KO')
		clearStatusEffects(combatant)
		if combatant is ResEnemyCombatant: 
			experience_earnt += combatant.getExperience()
			drop_summary += combatant.getDrops()
		
		COMBATANTS.erase(combatant)
	
	# Reset values
	run_once = true
	target_index = 0
	COMBATANTS.sort_custom(sortBySpeed)
	selected_item = null
	secondary_panel.hide()
	
	# Determinte next combatant
	if !selected_ability.INSTANT_CAST:
		active_index = incrementIndex(active_index,1,COMBATANTS.size())
		active_combatant = COMBATANTS[active_index]
		tickStatusEffects(active_combatant)
		while active_combatant.STAT_VALUES['hustle'] == -1:
			active_index = incrementIndex(active_index,1,COMBATANTS.size())
			active_combatant = COMBATANTS[active_index]
			tickStatusEffects(active_combatant)
	else:
		selected_ability.ENABLED = false
	
	if checkDialogue():
		triggerDialogue()
		await dialogue_done
	
	active_combatant.act()
	checkWin()

#********************************************************************************
# BASE SCENE NODE CONTROL
#********************************************************************************
func _on_attack_pressed():
	Input.action_release("ui_accept")
	
	selected_ability = active_combatant.ABILITY_SET[0]
	
	valid_targets = selected_ability.getValidTargets(COMBATANTS, true)
	target_state = selected_ability.getTargetType()
	action_panel.hide()
	await target_selected
	if active_combatant.isEquipped('weapon'):
		active_combatant.EQUIPMENT['weapon'].useDurability()
	runAbility()
	
func _on_skills_pressed():
	getPlayerAbilities(active_combatant.ABILITY_SET)
	if secondary_panel_container.get_child_count() == 0: return
	secondary_panel.show()
	secondary_panel_container.get_child(0).grab_focus()
	
	
func _on_items_pressed():
	getPlayerItems(PlayerGlobals.INVENTORY)
	if secondary_panel_container.get_child_count() == 0: return
	secondary_panel.show()
	secondary_panel_container.get_child(0).grab_focus()
	
func _on_equipment_pressed():
	getPlayerWeapons(PlayerGlobals.INVENTORY)
	if secondary_panel_container.get_child_count() == 0: return
	equip_button.disabled = false
	secondary_panel.show()
	secondary_panel_container.get_child(0).grab_focus()

func _on_inspect_pressed():
	target_state = 3

func _on_escape_pressed():
	concludeCombat(0)

func toggleUI():
	for child in get_children():
		if child is CombatBar:
			child.visible = !child.visible
		

#********************************************************************************
# ABILITY SELECTION, TARGETING, AND EXECUTION
#********************************************************************************
func getPlayerAbilities(ability_set: Array[ResAbility]):
	for child in secondary_panel_container.get_children():
		child.free()
	
	for i in range(len(ability_set)):
		if i == 0: continue
		var button = Button.new()
		button.add_theme_font_size_override('font_size', 16)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.x = 240
		button.text = ability_set[i].NAME
		button.pressed.connect(ability_set[i].execute)
		if !ability_set[i].canCast(active_combatant) or !ability_set[i].ENABLED:
			button.disabled = true
		secondary_panel_container.add_child(button)

func getPlayerItems(inventory):
	for child in secondary_panel_container.get_children():
		child.free()
		
	for item in inventory:
		if !item is ResConsumable or item.EFFECT == null: continue
		var button = Button.new()
		button.add_theme_font_size_override('font_size', 16)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.x = 240
		button.text = str(item.NAME, ' x', item.STACK)
		button.pressed.connect(item.EFFECT.execute)
		button.pressed.connect(
			func playerSelectItem(): 
				selected_item = item
				)
		secondary_panel_container.add_child(button)

func getPlayerWeapons(inventory):
	for child in secondary_panel_container.get_children():
		child.free()
		
	for weapon in inventory:
		if !weapon is ResWeapon: continue
		var button = Button.new()
		button.add_theme_font_size_override('font_size', 16)
		button.custom_minimum_size.x = 240
		button.text = str(weapon.NAME, '(', weapon.durability, '/', weapon.max_durability,')')
		button.pressed.connect( 
			func equipWeapon(): 
				weapon.equip(active_combatant) 
				resetActionLog()
				)
		if weapon.durability <= 0: button.disabled = true
		secondary_panel_container.add_child(button)

func playerSelectAbility(ability:ResAbility, state: int):
	target_state = state
	selected_ability = ability
	valid_targets = selected_ability.getValidTargets(COMBATANTS, true)
	secondary_panel.hide()
	action_panel.hide()
	await target_selected
	runAbility()

func playerSelectSingleTarget():
	if !validateAbilityCast() or getCombatantGroup('enemies').is_empty():
		return
	
	target_combatant = valid_targets[target_index]
	drawSelectionTarget('Target', target_combatant.getSprite().global_position)
	combat_camera.position = lerp(combat_camera.position, ui_target.position, 0.25)
	browseTargetsInputs()
	confirmCancelInputs()
	
func playerSelectMultiTarget():
	if !validateAbilityCast() or getCombatantGroup('enemies').is_empty():
		return
	
	drawSelectionTarget('Target', enemy_container.global_position)
	combat_camera.zoom = lerp(combat_camera.zoom, Vector2(0.75, 0.75), 0.25)
	target_combatant = selected_ability.getValidTargets(COMBATANTS, true)
	confirmCancelInputs()

func playerSelectInspection():
	action_panel.hide()
	valid_targets = COMBATANTS
	target_combatant = valid_targets[target_index]
	drawInspectionTarget(target_combatant.getSprite().global_position)
	combat_camera.position = lerp(combat_camera.position, ui_inspect_target.position, 0.25)
	ui_inspect_target.subject = target_combatant
	browseTargetsInputs()
	confirmCancelInputs()

func executeAbility():
	# NOTE TO SELF, PRELOAD AI PACKAGES TO AVOID LAG SPIKES
	selected_ability.animateCast(active_combatant)
	selected_ability.applyEffects(
								active_combatant, 
								target_combatant, 
								selected_ability.ANIMATION
								)
	await get_tree().create_timer(0.5).timeout
	if has_node('QTE'): await CombatGlobals.qte_finished
	
	if selected_item != null: selected_item.take(1)
	CombatGlobals.ability_used.emit(selected_ability)
	if checkDialogue():
		triggerDialogue()
		await dialogue_done
	confirm.emit()

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
func addCombatant(combatant, container):
	for marker in container:
		if marker.get_child_count() != 0: continue
		
		marker.add_child(combatant.SCENE)
		combatant.getAnimator().play('Idle')
		break
	
func connectPlayerAbilities(combatant: ResCombatant):	
	for ability in combatant.ABILITY_SET:
		if ability.single_target.is_connected(playerSelectAbility): continue
		ability.single_target.connect(playerSelectAbility)
		ability.multi_target.connect(playerSelectAbility)
		
func connectPlayerItems():
	for item in PlayerGlobals.INVENTORY:
		if !item is ResConsumable: continue
		if item.EFFECT != null: 
			if item.EFFECT.single_target.is_connected(playerSelectAbility): continue
			item.EFFECT.single_target.connect(playerSelectAbility)
			item.EFFECT.multi_target.connect(playerSelectAbility)
	
func spawnTroop(combatant):
	if combatant is ResPlayerCombatant or combatant.COUNT < 1:
		return
	
	var id = 2
	
	for n in combatant.COUNT-1:
		var temp_combatant = combatant.duplicate()
		temp_combatant.NAME += ' ' + str(id)
		id += 1
		temp_combatant.COUNT = 1
		COMBATANTS.append(temp_combatant)

func getDeadCombatants():
	return COMBATANTS.duplicate().filter(func getDead(combatant): return combatant.isDead())
	
func sortBySpeed(a: ResCombatant, b: ResCombatant):
	return a.STAT_VALUES['hustle'] > b.STAT_VALUES['hustle']

func getCombatantGroup(type)-> Array[ResCombatant]:
	match type:
		'team': return COMBATANTS.duplicate().filter(func getTeam(combatant): return combatant is ResPlayerCombatant)
		'enemies': return COMBATANTS.duplicate().filter(func getEnemies(combatant): return combatant is ResEnemyCombatant)
	
	return [null]

func checkWin():
	var enemies = getCombatantGroup('enemies')
	var team = getCombatantGroup('player')
	
	if enemies.is_empty():
		if unique_id != null:
			CombatGlobals.combat_won.emit(unique_id)
		
		if checkDialogue():
			triggerDialogue()
			await dialogue_done
		
		concludeCombat(1)
	
	elif team.is_empty():
		if unique_id != null:
			CombatGlobals.combat_lost.emit(unique_id)
		
		if checkDialogue():
			triggerDialogue()
			await dialogue_done
		
		concludeCombat(0)

func checkDialogue():
	if combat_dialogue == null:
		return false
	
	return combat_dialogue.dialogue_node.dialogue_triggered

func triggerDialogue():
	toggleUI()
	await DialogueManager.dialogue_ended
	toggleUI()
	combat_dialogue.dialogue_node.dialogue_triggered = false
	dialogue_done.emit()

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
	
func drawSelectionTarget(animation: String, pos: Vector2):
	ui_target.show()
	ui_target_animator.play(animation)
	ui_target.position = pos

func drawInspectionTarget(pos: Vector2):
	ui_inspect_target.show()
	ui_inspect_target.position = pos

func browseTargetsInputs():
	if Input.is_action_just_pressed("ui_right"):
		target_index = incrementIndex(target_index, 1, valid_targets.size())
	if Input.is_action_just_pressed("ui_left"):
		target_index = incrementIndex(target_index, -1, valid_targets.size())
	
func confirmCancelInputs():
	if Input.is_action_just_pressed("ui_accept") and target_state != 3:
		ui_target.hide()
		target_selected.emit()
	if Input.is_action_just_pressed("ui_cancel"):
		resetActionLog()
	
func resetActionLog():
	combat_camera.position = Vector2(0, -19)
	combat_camera.zoom = Vector2(1.0, 1.0)
	ui_inspect_target.hide()
	ui_target.hide()
	secondary_panel.hide()
	target_state = 0
	target_index = 0
	attack_button.grab_focus()
	action_panel.show()
	
func validateAbilityCast():
	if !selected_ability.canCast(active_combatant):
		resetActionLog()
		return false
	else:
		return true
	
func runAbility():
	target_state = 0
	if run_once:
		selected_ability.expendCost(active_combatant)
		executeAbility()
		action_panel.hide()
		run_once = false
	
func concludeCombat(results: int):
	for combatant in COMBATANTS:
		clearStatusEffects(combatant)
	
	action_panel.hide()
	ui_target.hide()
	secondary_panel.hide()
	target_state = 0
	target_index = 0
	
	var bc_ui = preload("res://scenes/user_interface/BattleConclusion.tscn").instantiate()
	bc_ui.drops = drop_summary
	add_child(bc_ui)
	
	CombatGlobals.emit_exp_updated(experience_earnt, PlayerGlobals.getRequiredExp())
	PlayerGlobals.addExperience(experience_earnt)
	
	await bc_ui.done
	
	if conclusion_dialogue != null:
		CombatGlobals.combat_conclusion_dialogue.emit(conclusion_dialogue, results)
	
	combat_done.emit()
	
	queue_free()

