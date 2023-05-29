# TO DO:
# 1. ABILITY EFFECTS
#		1.1 States

extends Node2D
class_name CombatScene

@export var COMBATANTS: Array[ResCombatant] = []

@onready var combat_camera = $CombatCamera
@onready var combat_log = $CombatLog
@onready var enemy_container = $EnemyContainer
@onready var team_container_markers = $TeamContainer.get_children()
@onready var enemy_container_markers = $EnemyContainer.get_children()
@onready var action_panel = $ActionPanel
@onready var attack_button = $ActionPanel/Attack
@onready var ability_scroller = $ActionPanel/Skills/SkillScroller
@onready var ability_container = $ActionPanel/Skills/SkillScroller/SkillsContainer
@onready var items_button = $ActionPanel/Items
@onready var escape_button = $ActionPanel/Escape
@onready var ui_target = $Target
@onready var ui_target_animator = $Target/TargetAnimator

var target_state = 0 # 0=None, 1=Single, 2=Multi
var active_combatant: ResCombatant
var active_index = 0
var valid_targets
var target_combatant
var target_index = 0
var selected_ability: ResAbility
var run_once = true

signal confirm
signal target_selected

#********************************************************************************
# INITIALIZATION AND COMBAT LOOP
#********************************************************************************
func _ready():
	for combatant in COMBATANTS:
		spawnTroop(combatant)
		combatant.initializeCombatant()
		combatant.player_turn.connect(on_player_turn)
		combatant.enemy_turn.connect(on_enemy_turn)
		
		if (combatant.IS_PLAYER_UNIT):
			addCombatant(combatant, team_container_markers)
			connectPlayerAbilities(combatant)
		else:
			addCombatant(combatant, enemy_container_markers)
	
	COMBATANTS.sort_custom(sortBySpeed)
	
	active_combatant = COMBATANTS[active_index]
	active_combatant.act()
	
func _process(_delta):
	match target_state:
		1: playerSelectSingleTarget()
		2: playerSelectMultiTarget()
	
func on_player_turn():
	checkWin()
	action_panel.show()
	attack_button.grab_focus()
	action_panel.position = active_combatant.getSprite().global_position
	await confirm
	end_turn()
	
func on_enemy_turn():
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
	else:
		checkWin()
	
func end_turn():
	for combatant in COMBATANTS:
		for effect in combatant.STATUS_EFFECTS:
			effect.tick()
		
	for combatant in getDeadCombatants():
		combatant.getAnimator().play('KO')
		COMBATANTS.erase(combatant)
	
	checkWin()
	run_once = true
	target_index = 0
	COMBATANTS.sort_custom(sortBySpeed)
	ability_scroller.hide()
	# Determinte next combatant
	active_index = incrementIndex(active_index,1,COMBATANTS.size())
	active_combatant = COMBATANTS[active_index]
	active_combatant.act()

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
	runAbility()
	
func _on_skills_pressed():
	getPlayerAbilities(active_combatant.ABILITY_SET)
	ability_scroller.show()
	ability_container.get_child(0).grab_focus()
	
func _ability_focus_exit():
	ability_scroller.hide()
	
func _ability_focus_enter():
	ability_scroller.show()
	
func _on_items_pressed():
	confirm.emit()
	
func _on_escape_pressed():
	get_tree().quit()
	
func writeCombatLog(text: String):
	combat_log.text = text
	combat_log.show()
	await get_tree().create_timer(1.5).timeout
	combat_log.hide()
	
#********************************************************************************
# ABILITY SELECTION, TARGETING, AND EXECUTION
#********************************************************************************
func getPlayerAbilities(ability_set: Array[ResAbility]):
	for child in ability_container.get_children():
		child.free()
	
	for i in range(len(ability_set)):
		if i == 0: continue
		var button = Button.new()
		button.text = ability_set[i].NAME
		button.pressed.connect(ability_set[i].execute)
		button.focus_entered.connect(_ability_focus_enter)
		button.focus_exited.connect(_ability_focus_exit)
		ability_container.add_child(button)
	
func playerSelectAbility(ability:ResAbility, state: int):
	target_state = state
	selected_ability = ability
	valid_targets = selected_ability.getValidTargets(COMBATANTS, true)
	action_panel.hide()
	await target_selected
	runAbility()
	
func playerSelectSingleTarget():
	if !validateAbilityCast():
		return
	
	target_combatant = valid_targets[target_index]
	drawSelectionTarget('Target', target_combatant.getSprite().global_position)
	browseTargetsInputs()
	confirmCancelInputs()
	
func playerSelectMultiTarget():
	if !validateAbilityCast():
		return
		
	drawSelectionTarget('Target', enemy_container.global_position)
	target_combatant = selected_ability.getValidTargets(COMBATANTS, true)
	confirmCancelInputs()
	
func executeAbility():
	writeCombatLog(str(active_combatant.NAME, ' casts ', selected_ability.NAME, '!'))
	add_child(selected_ability.ANIMATION.instantiate())
	# NOTE TO SELF, PRELOAD AI PACKAGES TO AVOID LAG SPIKES
	selected_ability.animateCast(active_combatant)
	selected_ability.applyEffects(
								active_combatant, 
								target_combatant, 
								get_node(selected_ability.ANIMATION_NAME)
								)
	await CombatGlobals.ability_executed
	get_node(selected_ability.ANIMATION_NAME).queue_free()
	confirm.emit()
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
	
func spawnTroop(combatant):
	if combatant.COUNT < 1:
		return
		
	for n in combatant.COUNT-1:
		var temp_combatant = combatant.duplicate()
		temp_combatant.COUNT = 1
		COMBATANTS.append(temp_combatant)
	
func getDeadCombatants():
	return COMBATANTS.duplicate().filter(func getDead(combatant): return combatant.isDead())
	
func sortBySpeed(a: ResCombatant, b: ResCombatant):
	return a.STAT_VALUES['hustle'] > b.STAT_VALUES['hustle']
	
func checkWin():
	var enemies = COMBATANTS.duplicate().filter(func getEnemies(combatant): return !combatant.IS_PLAYER_UNIT)
	var team = COMBATANTS.duplicate().filter(func getTeam(combatant): return combatant.IS_PLAYER_UNIT)
	
	if enemies.size() == 0: 
		print("You win!")
		# Clear all lingering status effects on end of combat
		for combatant in COMBATANTS:
			for status in combatant.STATUS_EFFECTS:
				status.removeStatusEffect()
		queue_free()
		OverworldGlobals.restorePlayerView()
	if team.size() == 0: 
		print("You LOSE!")
		queue_free()
		OverworldGlobals.restorePlayerView()
	
	
func incrementIndex(index:int, increment: int, limit: int):
	return (index + increment) % limit
	
func drawSelectionTarget(animation: String, pos: Vector2):
	ui_target.show()
	ui_target_animator.play(animation)
	ui_target.position = pos
	
func browseTargetsInputs():
	if Input.is_action_just_pressed("ui_right"):
		target_index = incrementIndex(target_index, 1, valid_targets.size())
	if Input.is_action_just_pressed("ui_left"):
		target_index = incrementIndex(target_index, -1, valid_targets.size())
	
func confirmCancelInputs():
	if Input.is_action_just_pressed("ui_accept"):
		ui_target.hide()
		target_selected.emit() 
	if Input.is_action_just_pressed("ui_cancel"):
		resetActionLog()
	
func resetActionLog():
	ui_target.hide()
	target_state = 0
	target_index = 0
	attack_button.grab_focus()
	action_panel.show()
	
func validateAbilityCast():
	if !selected_ability.canCast(active_combatant):
		writeCombatLog('Not enough resources!')
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
