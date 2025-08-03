extends CanvasLayer

@onready var animator = $AnimationPlayer
@onready var main_container = $VBoxContainer

func _ready():
	loadCombatants()
	animator.play("Show")
	await get_tree().create_timer(2.5).timeout
	animator.play_backwards("Show")
	await animator.animation_finished
	queue_free()

func loadCombatants():
	for combatant in OverworldGlobals.getCombatantSquad('Player'):
		var bar = load("res://scenes/user_interface/GeneralCombatantStatus.tscn").instantiate()
		bar.combatant = combatant
		if combatant.isDead(): 
			bar.modulate = Color.RED
		main_container.add_child(bar)
