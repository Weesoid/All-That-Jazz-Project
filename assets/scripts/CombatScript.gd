# TO DO:
# 1. ABILITY EFFECTS
#		1.1 Targeting
#		1.2 Ability Effects (damaging health, changing stats, etc)
#		1.3 Visual Effects (Damage numbers, update health bar)
# 2. AI TO USE THE ABILITIES
#
# MISC:
# 1. Different target states (Single, multi, rando)
# 2. States, they're basically abilities that occur each turn or something, run state method?

extends Node2D

## This bool determines when the player is able to target enemies
var state = false
## The combatant whose turn it is.
var active_combatant: Combatant
## Index for the active combatant.
var active_index = 0
## The player targeted combatant.
var target_combatant: Combatant
## Index for the target combatant.
var target_index = 0

var debug_attack: Ability # Debugging purposes only

## An array of every combatant on the field.
## Use this array to access combatant info.
@export var COMBATANTS: Array[Combatant] = []
## Onready variable for the team container. Player controlled combatants will be visually placed here.
@onready var team_container = $TeamContainer.get_children()
## Onready variable for the enemy container. enemy combatants will be visually placed here.
@onready var enemy_container = $EnemyContainer.get_children()

## Singal for when player confirms their action.
signal confirm
## Signal for when player has selected their target.
signal target_selected
## Signal for when a combatant finishes their animation.
signal anim_finished

## Init
func _ready():
	# BASIS FOR AI PACKAGES
	#var script = load("res://assets/scripts/ai_packages/DefaultAI.gd")
	#var integer = script.returnInt(12)
	#print(integer)
		
	debug_attack = load("res://assets/resources/abilities/Punch.tres") # debug
	debug_attack.initializeAbility() # debug
	spawnTroops()
	
	# Place combatants on the field and connect their signals
	for combatant in COMBATANTS:
		# Initialize combatant
		combatant.initializeCombatant()
		combatant.player_turn.connect(on_player_turn)
		combatant.enemy_turn.connect(on_enemy_turn)

		# Add combatants to appropriate positions
		if (combatant.IS_PLAYER_UNIT):
			for marker in team_container:
				if marker.get_child_count() == 0:
					marker.add_child(combatant.SCENE)
					combatant.getAnimator().play('Idle')
					break
		else:
			for marker in enemy_container:
				if marker.get_child_count() == 0:
					marker.add_child(combatant.SCENE)
					combatant.getAnimator().play('Idle')
					break
	
	COMBATANTS.sort_custom(sortBySpeed)
	
	# Start the combat loop by making the first combatant act.
	active_combatant = COMBATANTS[active_index]
	active_combatant.act()

## Sort combatants by their speed.
func sortBySpeed(a: Combatant, b: Combatant):
	return a.STAT_SPEED > b.STAT_SPEED

## Determine what state the combat encounter is in and act accordingly.
func _process(_delta):
	if state:
		selectTarget()
	
## Show player GUI and wait for them to confirm their action.
func on_player_turn():
	print('player turn!')
	$ActionPanel.show()
	await confirm
	end_turn()
	
## Execute enemy turn.
func on_enemy_turn():
	print('enemy turn!')
	#print(active_combatant.NAME, ' is ACTING!')
	$ActionPanel.hide()
	#$CombatLog.text = str(active_combatant.NAME, " does a FLIP!")
	playCombatantAnim(active_combatant, 'Attack')
	print('waitng..')
	await anim_finished # FOR DEBUG ONLY
	end_turn()
	
## End turn. This is the main thing that keeps combat running. Very important.
func end_turn():
	#COMBATANTS.sort_custom(sortBySpeed) Might break later, uncomment when you have speed adjusting abilities
	if (active_index + 1 < COMBATANTS.size()):
		active_index += 1
	else:
		active_index = 0
	
	print('Index ', active_index, ' is ACTING')
	active_combatant = COMBATANTS[active_index]
	active_combatant.act()

## Signal for when the attack button is pressed.
func _on_attack_pressed():
	#print('ATTACKING!')
	state = true
	await target_selected
	state = false
	executeAbility(debug_attack, target_combatant)

## Function for selecting a target.
## Single Target Function
## TO-DO: MULTI, RANDOM target function plus boolean to select specific targets (team or enemies)
func selectTarget():
	target_combatant = COMBATANTS[target_index]
	target_combatant.getSprite().scale = Vector2(1.1,1.1)
	
	# ABSTRACT THIS INTO FUNCTION (maybe)
	if Input.is_action_just_pressed("ui_right"):
		target_combatant.getSprite().scale = Vector2(1,1)
		if (target_index + 1 < COMBATANTS.size()):
			target_index += 1
		else:
			target_index = 0
	if Input.is_action_just_pressed("ui_left"):
		target_combatant.getSprite().scale = Vector2(1,1)
		if (target_index - 1 >= 0):
			target_index -= 1
		else:
			target_index = COMBATANTS.size() - 1
	if Input.is_action_just_pressed("ui_accept"):
		target_combatant.getSprite().scale = Vector2(1,1)
		target_selected.emit()

## Function for executing an ability. (Maybe enemy combatants can use this???)
func executeAbility(ability_res: Ability, target: Combatant):
	#print(ability_res.ANIMATION_NAME)
	add_child(ability_res.ANIMATION)
	
	get_node(ability_res.ANIMATION_NAME).position = target_combatant.SCENE.global_position
	var anim_player: AnimationPlayer = get_node(ability_res.ANIMATION_NAME).get_node("Animator")
	anim_player.play('Execute')
	# pseudo: target = ability_res.ABILITY_SCRIPT.applyEffects(target)
	target_combatant.getAnimator().play('Hit')
	await target_combatant.getAnimator().animation_finished
	target_combatant.getAnimator().play('Idle')
	await anim_player.animation_finished
	confirm.emit()
	
	remove_child(ability_res.ANIMATION)
	
## Plays an animation for a combatant.
## Unlike .getAnimator().play(), this script waits for this animation to finish before continuing.
func playCombatantAnim(combatant: Combatant, animation):
	#print('Triggering ', combatant)
	combatant.getAnimator().play(animation)
	await combatant.getAnimator().animation_finished
	combatant.getAnimator().play('Idle')
	anim_finished.emit()
	print('Emitting anim finsihed!')
	
## Spawn troop combatants.
## Troops combatants are combatants with a count that's greater than 1.
func spawnTroops():
	for combatant in COMBATANTS:
		if combatant.COUNT > 1:
			for n in combatant.COUNT-1:
				var temp_combatant = combatant.duplicate()
				temp_combatant.COUNT = 1
				COMBATANTS.append(temp_combatant)
