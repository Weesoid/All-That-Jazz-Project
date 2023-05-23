# TO DO:
# 1. ABILITY EFFECTS
#		1.1 States
#		1.2 Targeting
#		1.1 Equipping and inventory system
#		1.3 Visual Effects (Damage numbers)
#
# MISC:
# 1. Different target states (Single, multi, rando)
# 2. States, they're basically abilities that occur each turn or something, run state method?

extends Node2D

@export var COMBATANTS: Array[Combatant] = []
@onready var team_container = $TeamContainer.get_children()
@onready var enemy_container = $EnemyContainer.get_children()
@onready var action_panel = $ActionPanel
@onready var attack_button = $ActionPanel/Attack
@onready var ability_scroller = $ActionPanel/Skills/SkillScroller
@onready var ability_container = $ActionPanel/Skills/SkillScroller/SkillsContainer
@onready var items_button = $ActionPanel/Items
@onready var escape_button = $ActionPanel/Escape

var target_state = 0 # 0=None, 1=Single, 2=Multi, 3=Random
var active_combatant: Combatant
var active_index = 0
var target_combatant: Combatant
var target_index = 0
var valid_targets: Array[Combatant] = []
var selected_ability: Ability
var run_once = true

signal confirm
signal target_selected
signal anim_finished

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
			addCombatant(combatant, team_container)
			connectPlayerAbilities(combatant)
		else:
			addCombatant(combatant, enemy_container)
	
	COMBATANTS.sort_custom(sortBySpeed)
	
	active_combatant = COMBATANTS[active_index]
	active_combatant.act()
	
func _process(_delta):
	match target_state:
		1: playerSelectSingleTarget()
		2: print('Multi!')
		3: print('Rando!')
	
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
	target_combatant = active_combatant.AI_PACKAGE.selectTarget(valid_targets)
	
	if (target_combatant != null):
		executeAbility()
		await confirm
		end_turn()
	else:
		checkWin()
	
func end_turn():
	# Check and reset stuff
	for combatant in COMBATANTS: 
		removeDeadCombatant(combatant)
	run_once = true
	target_index = 0
	ability_scroller.hide()
	COMBATANTS.sort_custom(sortBySpeed)
	
	# Determinte next combatant
	if (active_index + 1 < COMBATANTS.size()):
		active_index += 1
	else:
		active_index = 0
	active_combatant = COMBATANTS[active_index]
	active_combatant.act()

#********************************************************************************
# SCENE BUTTON SIGNALS
#********************************************************************************
func _on_attack_pressed():
	Input.action_release("ui_accept")
	selected_ability = active_combatant.ABILITY_SET[0]
	valid_targets = selected_ability.getValidTargets(COMBATANTS, true)
	target_state = 1
	action_panel.hide()
	await target_selected
	target_state = 0
	if run_once:
		executeAbility()
		action_panel.hide()
		run_once = false
	
func _on_skills_pressed():
	ability_scroller.visible = !ability_scroller.visible
	getPlayerAbilities(active_combatant.ABILITY_SET)
	
func _on_escape_pressed():
	pass
	
#********************************************************************************
# ABILITY SELECTION, TARGETING, AND EXECUTION
#********************************************************************************
func getPlayerAbilities(ability_set: Array[Ability]):
	for child in ability_container.get_children():
		child.free()
	
	for ability in ability_set:
		var button = Button.new()
		button.text = ability.NAME
		button.pressed.connect(ability.execute)
		ability_container.add_child(button)
	
func playerSelectAbility(ability:Ability, state: int):
	target_state = state
	selected_ability = ability
	valid_targets = selected_ability.getValidTargets(COMBATANTS, true)
	action_panel.hide()
	await target_selected
	target_state = 0
	if run_once:
		executeAbility()
		action_panel.hide()
		run_once = false
	
func playerSelectSingleTarget():
	target_combatant = valid_targets[target_index]
	target_combatant.getSprite().scale = Vector2(1.1,1.1)
	
	# ABSTRACT THIS INTO FUNCTION (maybe)
	if Input.is_action_just_pressed("ui_right"):
		target_combatant.getSprite().scale = Vector2(1,1)
		if (target_index + 1 < valid_targets.size()):
			target_index += 1
		else:
			target_index = 0
	if Input.is_action_just_pressed("ui_left"):
		target_combatant.getSprite().scale = Vector2(1,1)
		if (target_index - 1 >= 0):
			target_index -= 1
		else:
			target_index = valid_targets.size() - 1
	if Input.is_action_just_pressed("ui_accept"):
		target_combatant.getSprite().scale = Vector2(1,1)
		target_selected.emit() 
	if Input.is_action_just_pressed("ui_cancel"):
		target_state = 0
		attack_button.grab_focus()
		action_panel.show()
	
func playerSelectMultiTarget():
	print('MULTI')
		
func playerSelectRandomTarget():
	print('RANDOM')
	
func executeAbility(): 
	add_child(selected_ability.ANIMATION)
	
	# NOTE TO SELF, PRELOAD AI PACKAGES TO AVOID LAG SPIKES
	selected_ability.ABILITY_SCRIPT.animateCast(active_combatant)
	selected_ability.ABILITY_SCRIPT.applyEffects(
										active_combatant, 
										target_combatant, 
										get_node(selected_ability.ANIMATION_NAME)
									)
	await selected_ability.getAnimator().animation_finished
	
	remove_child(selected_ability.ANIMATION)
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
	
func connectPlayerAbilities(combatant: Combatant):	
	for ability in combatant.ABILITY_SET:
		if ability.single_target.is_connected(playerSelectAbility): continue
		
		ability.single_target.connect(playerSelectAbility)
		ability.multi_target.connect(playerSelectAbility)
		ability.random_target.connect(playerSelectAbility)
	
func spawnTroop(combatant):
	if combatant.COUNT < 1:
		return
		
	for n in combatant.COUNT-1:
		var temp_combatant = combatant.duplicate()
		temp_combatant.COUNT = 1
		COMBATANTS.append(temp_combatant)
	
func removeDeadCombatant(combatant):
	if combatant.STAT_HEALTH <= 0:
		combatant.getAnimator().play('KO')
		COMBATANTS.erase(combatant)
	
func sortBySpeed(a: Combatant, b: Combatant):
	return a.STAT_SPEED > b.STAT_SPEED
	
func checkWin():
	var enemies = COMBATANTS.duplicate().filter(func getEnemies(combatant: Combatant): return !combatant.IS_PLAYER_UNIT)
	var team = COMBATANTS.duplicate().filter(func getTeam(combatant: Combatant): return combatant.IS_PLAYER_UNIT)
	
	print('CHECKING ', enemies.size(), ' ', team.size())
	
	if enemies.size() == 0: 
		print("You win!")
		get_tree().quit()
	if team.size() == 0: 
		print("You LOSE!")
		get_tree().quit()
	
