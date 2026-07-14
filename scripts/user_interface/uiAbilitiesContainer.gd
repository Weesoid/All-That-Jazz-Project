extends Container

@onready var pool = $AbilityContainer/GridContainer

func loadAbilities(combatant: ResPlayerCombatant):
	if combatant.ability_pool.is_empty():
		return
	
	for ability in combatant.ability_pool:
		if ability == null:
			combatant.ability_pool.erase(ability)
			continue
		
		createAbilityButton(ability, combatant)
	hideLocked(combatant)
	if combatant.ability_set.size() >= 5:
		dimInactiveAbilities(combatant)
	#loadDebug(combatant)

func loadDebug(combatant):
	for i in range(10):
		createAbilityButton(combatant.ability_pool.pick_random(), combatant)

func createAbilityButton(ability, combatant):
	var button: CustomButton = UIGlobals.createAbilityButton(ability)
	var has_unlocked = PlayerGlobals.hasUnlockedAbility(combatant, ability) #or ability.required_level == 0
	button.focused_entered_sound = load("res://audio/sounds/421354__jaszunio15__click_31.ogg")
	button.click_sound = load("res://audio/sounds/421304__jaszunio15__click_229.ogg")
	if combatant.ability_set.has(ability):
		button.add_theme_icon_override('icon', load("res://images/sprites/ability_mark.png"))
	
	pool.add_child(button)
	if !has_unlocked:
		giveButtonUnlockAbility(button, combatant, ability)
		button.setLocked(true)
	else:
		giveButtonToggleActive(button, combatant, ability)

func giveButtonToggleActive(button:CustomButton, combatant:ResPlayerCombatant, ability: ResAbility):
	button.pressed.connect(
		func():
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

func giveButtonUnlockAbility(button:CustomButton, combatant:ResPlayerCombatant, ability: ResAbility):
	button.setCost(combatant)
	button.hold_time = 0.25
	button.held_press.connect(
		func():
			var ability_cost = PlayerGlobals.getAbilityCost(combatant)
			if !InventoryGlobals.hasItem('Remembrance', ability_cost): 
				return
			
			InventoryGlobals.removeItemWithName('Remembrance',ability_cost)
			PlayerGlobals.unlockAbility(combatant, ability)
			OverworldGlobals.playSound('res://audio/sounds/721774__maodin204__cash-register.ogg')
			button.setLocked(false)
			button.hold_time = -1
			giveButtonToggleActive(button, combatant, ability)
			updateLockedCosts(combatant)
			if combatant.ability_set.size() >= PlayerGlobals.ability_cap: dimInactiveAbilities(combatant)
			#await get_tree().process_frame
			hideLocked(combatant)
	)

func updateLockedCosts(combatant:ResPlayerCombatant):
	for locked_ability in pool.get_children():
		if !locked_ability.is_locked: continue
		locked_ability.setCost(combatant)

func hideLocked(combatant:ResPlayerCombatant):
	if PlayerGlobals.getLockedAbilities(combatant).size() <= 0:
		return
	
	var eligeble_ability = PlayerGlobals.getLockedAbilities(combatant)[0]
	for button in pool.get_children():
		if !button.is_locked or button.ability == eligeble_ability: 
			#button.modulate = Color.WHITE
			button.show()
			continue
		if button.visible:
			#button.modulate = Color(Color.WHITE,0.5)
			button.hide()

func dimInactiveAbilities(combatant):
	for ability_button in pool.get_children():
		if ability_button.is_locked:continue
		ability_button.setDisabled(!combatant.ability_set.has(ability_button.ability))

func undimAbilities():
	for ability_button in pool.get_children():
		if ability_button.is_locked:continue
		ability_button.setDisabled(false)

func clear():
	for button in pool.get_children():
		button.queue_free()
