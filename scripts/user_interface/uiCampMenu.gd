extends Control

@onready var action_container = $HBoxContainer
@onready var rest_container = $HBoxContainer2
@onready var eat_button = $HBoxContainer/Eat
@onready var craft_button = $HBoxContainer/Craft
@onready var travel_button = $HBoxContainer/FastTravel
@onready var back_button = $BackButton
@onready var rest_button = $Rest
@onready var no_rest_button = $NoRest
@onready var rest_ui = $RestStuff
@onready var confirm_rest = $RestStuff/Button
@onready var player = OverworldGlobals.getPlayer()
@onready var squad = OverworldGlobals.getCombatantSquad('Player')

var wake_events = []
var guard_combatant: ResPlayerCombatant

func _ready():
	showContainer(action_container)

func _on_eat_pressed():
	loadUserInterface("res://scenes/user_interface/Saves.tscn")

func _on_craft_pressed():
	loadUserInterface("res://scenes/user_interface/Crafting.tscn")

func _on_fast_travel_pressed():
	loadUserInterface("res://scenes/user_interface/FastTravel.tscn")

func setButtons(set_to:bool):
	for button in action_container.get_children():
		button.visible = set_to

func loadUserInterface(path):
	var ui = load(path).instantiate()
	ui.name = 'Menu'
	setButtons(false)
	add_child(ui)
	back_button.show()

func tweenAbilityButtons(buttons: Array):
	for button in buttons:
		button.modulate = Color.TRANSPARENT
	await get_tree().process_frame
	for button in buttons:
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(button, 'scale', Vector2(1.1,1.1), 0.005)
		tween.tween_property(button, 'scale', Vector2(1.0,1.0), 0.05)
		tween.set_parallel(true)
		tween.tween_property(button, 'modulate', Color.WHITE, 0.0025)
		await tween.finished
		OverworldGlobals.playSound('536805__egomassive__gun_2.ogg',-6.0)

func _on_back_button_pressed():
	back_button.hide()
	get_node('Menu').queue_free()
	setButtons(true)
	showContainer(action_container)

func showContainer(container):
	for control in get_children().filter(func(control): return control is Container):
		control.hide()
	
	container.show()
	await tweenAbilityButtons(container.get_children())
	OverworldGlobals.setMenuFocus(container)


func _on_rest_pressed():
	setButtons(false)
	rest_button.hide()
	no_rest_button.hide()
	rest_ui.show()

func _on_confirm_rest_pressed():
	rest_ui.hide()
	no_rest_button.hide()
	await player.player_camera.showOverlay(Color.BLACK, 1.0, 1.0)
	for combatant in squad:
		if combatant == guard_combatant: continue
		restCombatant(combatant)
	await get_tree().create_timer(3.0).timeout
	OverworldGlobals.getCurrentMap().get_node('SavePoint').done.emit()
	queue_free()

func restCombatant(combatant: ResPlayerCombatant):
	CombatGlobals.removeStatusFaded(combatant)
	CombatGlobals.calculateHealing(combatant, combatant.getMaxHealth()*0.05)

func _on_no_rest_pressed():
	action_container.hide()
	rest_button.hide()
	no_rest_button.hide()
	await player.player_camera.showOverlay(Color.BLACK, 1.0, 1.0)
	await get_tree().create_timer(1.5).timeout
	OverworldGlobals.getCurrentMap().get_node('SavePoint').done.emit()
	queue_free()
