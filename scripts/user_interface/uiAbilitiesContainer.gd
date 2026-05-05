extends VBoxContainer

@onready var pool = $AbilityContainer/GridContainer

func loadAbilities(combatant: ResPlayerCombatant):
	if combatant.ability_pool.is_empty():
		return
	
	for ability in combatant.ability_pool:
		if ability == null:
			combatant.ability_pool.erase(ability)
			continue
		if PlayerGlobals.team_level < ability.required_level:
			continue
		createAbilityButton(ability, combatant)
	
	loadDebug(combatant)

func loadDebug(combatant):
	for i in range(10):
		createAbilityButton(combatant.ability_pool.pick_random(), combatant)

func createAbilityButton(ability, combatant):
	var button: CustomButton = OverworldGlobals.createAbilityButton(ability)
	var has_unlocked = PlayerGlobals.hasUnlockedAbility(combatant, ability) or ability.required_level == 0
	button.focused_entered_sound = load("res://audio/sounds/421354__jaszunio15__click_31.ogg")
	button.click_sound = load("res://audio/sounds/421304__jaszunio15__click_229.ogg")
	if combatant.ability_set.has(ability):
		button.add_theme_icon_override('icon', load("res://images/sprites/ability_mark.png"))
	if !has_unlocked:
		button.add_theme_icon_override('icon', load("res://images/sprites/lock.png"))
		button.tooltip_text = str(ability.getCost())
	
	button.pressed.connect(
		func():
			if !has_unlocked:
				if button.has_focus() and PlayerGlobals.currency >= ability.getCost() and !PlayerGlobals.hasUnlockedAbility(combatant, ability):
					PlayerGlobals.currency -= ability.getCost()
					PlayerGlobals.unlockAbility(combatant, ability)
					OverworldGlobals.playSound('res://audio/sounds/721774__maodin204__cash-register.ogg')
					#loadMemberInfo(combatant)
			else:
				PlayerGlobals.setAbilityActive(combatant, ability, !combatant.ability_set.has(ability))
			
			if combatant.ability_set.has(ability):
				button.add_theme_icon_override('icon', load("res://images/sprites/ability_mark.png"))
			else:
				button.remove_theme_icon_override('icon')
			
			if combatant.ability_set.size() >= PlayerGlobals.ability_cap:
				dimInactiveAbilities(combatant)
			elif combatant.ability_set.size() < PlayerGlobals.ability_cap:
				undimAbilities()
	)
	pool.add_child(button)

func dimInactiveAbilities(combatant):
	for ability_button in pool.get_children():
		ability_button.setDisabled(!combatant.ability_set.has(ability_button.ability))

func undimAbilities():
	for ability_button in pool.get_children():
		ability_button.setDisabled(false)
