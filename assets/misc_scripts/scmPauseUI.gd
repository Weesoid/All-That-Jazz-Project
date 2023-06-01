extends Control

func _ready():
	OverworldGlobals.player_can_move = false
	$Container/Inventory.grab_focus()

func _on_tree_exited():
	OverworldGlobals.player_can_move = true
	queue_free()
	
func _on_inventory_pressed():
	var inventory_ui = load("res://main_scenes/user_interface/uiInventory.tscn").instantiate()
	$Container.modulate.a = 0
	add_child(inventory_ui)
	
func _on_quit_pressed():
	get_tree().quit()
