extends Control

@onready var animator = $AnimationPlayer
@onready var main_container = $VBoxContainer
@onready var bar_template:CharacterBar = $VBoxContainer/CharacterBarTemplate

func _ready():
	await get_tree().create_timer(0.2).timeout
	OverworldGlobals.party_damaged.connect(popUp)
	loadCombatants()

func popUp():
	if animator.is_playing():
		return
	#for bar in main_container: bar.setHealthValue(combatant.stat_values['health'])
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, 'modulate', Color.RED,0.05)
	tween.tween_property(self, 'modulate', Color.WHITE,0.75)
	animator.play("Show")
	await get_tree().create_timer(3).timeout
	animator.play_backwards("Show")
	#await animator.animation_finished
	#queue_free()

func loadCombatants():
	for combatant in OverworldGlobals.getCombatantSquad('Player'):
		var bar:CharacterBar = load("res://scenes/user_interface/CharacterBar.tscn").instantiate()
		bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
		bar.right_aligned=true
		main_container.add_child(bar)
		bar.setCharacter(combatant)
#		var bar = bar_template.duplicate()
#		main_container.add_child(bar)
#		bar.setCharacter(combatant)
#		bar.show()
		#bar.size_flags_vertical = Control.SIZE_EXPAND_FILL

#		var bar = bar_template.duplicate()
#		main_container.add_child(bar)
#		bar.setCharacter(combatant)
#		bar.show()

func _on_tree_exited():
	for bar in main_container.get_children():
		bar.queue_free()
