extends Node2D
class_name CombatScene

@export var COMBATANTS: Array[ResCombatant]

@onready var combat_camera = $CombatCamera
@onready var combat_log = $CombatLog
@onready var enemy_container = $EnemyContainer
@onready var team_container_markers = $TeamContainer.get_children()
@onready var enemy_container_markers = $EnemyContainer.get_children()
@onready var action_panel = $ActionPanel
@onready var attack_button = $ActionPanel/Attack
@onready var ability_scroller = $ActionPanel/Skills/SkillScroller
@onready var ability_container = $ActionPanel/Skills/SkillScroller/SkillsContainer
@onready var item_scroller = $ActionPanel/Items/ItemScroller
@onready var item_container = $ActionPanel/Items/ItemScroller/ItemContainer
@onready var items_button = $ActionPanel/Items
@onready var equip_scroller = $ActionPanel/Equipment/ItemScroller
@onready var equip_container = $ActionPanel/Equipment/ItemScroller/ItemContainer
@onready var equip_button = $ActionPanel/Equipment
@onready var escape_button = $ActionPanel/Escape
@onready var ui_target = $Target
@onready var ui_target_animator = $Target/TargetAnimator
@onready var battle_conclusion = $BattleConclusion
@onready var party_exp_bar = $BattleConclusion/PartyExp
@onready var party_drops = $BattleConclusion/Drops/DropGrid

var target_state = 0 # 0=None, 1=Single, 2=Multi
var active_combatant: ResCombatant
var active_index = 0
var valid_targets
var target_combatant
var target_index = 0
var selected_ability: ResAbility
var run_once = true
var experience_earnt = 0
var item_drops = []

signal confirm
signal target_selected
signal update_exp(value: float, max_value: float)


#********************************************************************************
# INITIALIZATION AND COMBAT LOOP
#********************************************************************************
func _ready():
	CombatGlobals.call_indicator.connect(playIndicatorAnimation)
	
	connectPlayerItems()
	
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
	# TO-DO: Battle Transition
	
func _process(_delta):
	match target_state:
		1: playerSelectSingleTarget()
		2: playerSelectMultiTarget()
	
func on_player_turn():
	#checkWin()
	action_panel.show()
	attack_button.grab_focus()
	action_panel.global_position = active_combatant.getSprite().global_position - Vector2(0, 60)
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
		refreshInstantCasts(combatant)
		tickStatusEffects(combatant)
		
	for combatant in getDeadCombatants():
		combatant.getAnimator().play('KO')
		if combatant is ResEnemyCombatant: 
			experience_earnt += combatant.getExperience()
			item_drops.append(combatant.getDrops())
		COMBATANTS.erase(combatant)
	
	# Reset values
	run_once = true
	target_index = 0
	COMBATANTS.sort_custom(sortBySpeed)
	ability_scroller.hide()
	# Determinte next combatant
	if !selected_ability.INSTANT_CAST:
		active_index = incrementIndex(active_index,1,COMBATANTS.size())
		active_combatant = COMBATANTS[active_index]
	else:
		selected_ability.ENABLED = false
	
	active_combatant.act()
	checkWin()

#********************************************************************************
# BASE SCENE NODE CONTROL
#********************************************************************************
func _on_attack_pressed():
	Input.action_release("ui_accept")
	
	selected_ability = active_combatant.ABILITY_SET[0]
	if active_combatant.isEquipped('weapon'):
		active_combatant.EQUIPMENT['weapon'].useDurability()
	
	valid_targets = selected_ability.getValidTargets(COMBATANTS, true)
	target_state = selected_ability.getTargetType()
	action_panel.hide()
	await target_selected
	runAbility()
	
func _on_skills_pressed():
	getPlayerAbilities(active_combatant.ABILITY_SET)
	if ability_container.get_child_count() == 0: return
	ability_scroller.show()
	ability_container.get_child(0).grab_focus()
	
func _ability_focus_exit():
	ability_scroller.hide()
	
func _ability_focus_enter():
	ability_scroller.show()
	
func _on_items_pressed():
	getPlayerItems(PlayerGlobals.INVENTORY)
	if item_container.get_child_count() == 0: return
	items_button.disabled = false
	item_scroller.show()
	item_container.get_child(0).grab_focus()
	
func _item_focus_exit():
	item_scroller.hide()
	
func _item_focus_enter():
	item_scroller.show()
	
func _equip_focus_exit():
	equip_scroller.hide()
	
func _equip_focus_enter():
	equip_scroller.show()
	
func _on_equipment_pressed():
	getPlayerWeapons(PlayerGlobals.INVENTORY)
	if equip_container.get_child_count() == 0: return
	equip_button.disabled = false
	equip_scroller.show()
	equip_container.get_child(0).grab_focus()
	
func _on_escape_pressed():
	get_tree().quit()
	
func playIndicatorAnimation(target: ResCombatant, message: String, value):
	var indicator = load("res://scenes/components/Indicator.tscn").instantiate()
	add_child(indicator)
	indicator.global_position = target.getSprite().global_position
	indicator.get_node("IndicatorLabel").text = str(message,' ',value)
	indicator.get_node("Animator").play('Show')
	await indicator.get_node("Animator").animation_finished
	indicator.queue_free()
	
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
		if !ability_set[i].canCast(active_combatant) or !ability_set[i].ENABLED:
			button.disabled = true
		ability_container.add_child(button)

func getPlayerItems(inventory):
	for child in item_container.get_children():
		child.free()
		
	for item in inventory:
		if !item is ResConsumable or item.EFFECT == null: continue
		var button = Button.new()
		button.text = str(item.NAME, ' x', item.STACK)
		button.pressed.connect(item.EFFECT.execute)
		button.pressed.connect(item.use)
		button.focus_entered.connect(_item_focus_enter)
		button.focus_exited.connect(_item_focus_exit)
		item_container.add_child(button)

func getPlayerWeapons(inventory):
	for child in equip_container.get_children():
		child.free()
		
	for weapon in inventory:
		if !weapon is ResWeapon: continue
		var button = Button.new()
		button.text = str(weapon.NAME, '(', weapon.durability.x, '/', weapon.durability.y,')')
		button.pressed.connect( 
			func equipWeapon(): 
				weapon.equip(active_combatant) 
				resetActionLog()
				)
		button.focus_entered.connect(_equip_focus_enter)
		button.focus_exited.connect(_equip_focus_exit)
		if weapon.durability.x <= 0: button.disabled = true
		equip_container.add_child(button)

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
	var animation = selected_ability.ANIMATION.instantiate()
	writeCombatLog(str(active_combatant.NAME, ' casts ', selected_ability.NAME, '!'))
	add_child(animation)
	# NOTE TO SELF, PRELOAD AI PACKAGES TO AVOID LAG SPIKES
	selected_ability.animateCast(active_combatant)
	selected_ability.applyEffects(
								active_combatant, 
								target_combatant, 
								animation
								)
	await CombatGlobals.ability_executed
	animation.queue_free()
	
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
		
	for n in combatant.COUNT-1:
		var temp_combatant = combatant.duplicate()
		temp_combatant.COUNT = 1
		COMBATANTS.append(temp_combatant)
	
func getDeadCombatants():
	return COMBATANTS.duplicate().filter(func getDead(combatant): return combatant.isDead())
	
func sortBySpeed(a: ResCombatant, b: ResCombatant):
	return a.STAT_VALUES['hustle'] > b.STAT_VALUES['hustle']
	
func checkWin():
	var enemies = COMBATANTS.duplicate().filter(func getEnemies(combatant): return combatant is ResEnemyCombatant)
	var team = COMBATANTS.duplicate().filter(func getTeam(combatant): return combatant is ResPlayerCombatant)
	
	# TO-DO Win-Lose signals
	if enemies.is_empty():
		print("You win!")
		concludeCombat()
	elif team.is_empty():
		print("You LOSE!")
		concludeCombat()

	
func clearStatusEffects(combatant: ResCombatant):
	while !combatant.STATUS_EFFECTS.is_empty():
		combatant.STATUS_EFFECTS[0].removeStatusEffect()

func tickStatusEffects(combatant: ResCombatant):
	for effect in combatant.STATUS_EFFECTS:
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
	
func concludeCombat():
	for combatant in COMBATANTS:
		clearStatusEffects(combatant)
	
	action_panel.hide()
	ui_target.hide()
	target_state = 0
	target_index = 0
	battle_conclusion.show()
	CombatGlobals.emit_exp_updated(experience_earnt, PlayerGlobals.getRequiredExp())
	item_drops.sort()
	
	for drop in item_drops:
		if drop == null: continue
		var drop_label = Label.new()
		drop_label.text = drop.NAME
		party_drops.add_child(drop_label)
		PlayerGlobals.addItemResourceToInventory(drop)
	
	await get_tree().create_timer(1.5).timeout
	
	PlayerGlobals.addExperience(experience_earnt)
	OverworldGlobals.restorePlayerView()
	queue_free()
	
