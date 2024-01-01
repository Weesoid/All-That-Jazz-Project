extends Area2D

var patroller_name: String

func interact():
	print('Fight!')
	OverworldGlobals.changeToCombat(patroller_name, '', '', 'Dazed')
	OverworldGlobals.show_player_interaction = true
	queue_free()
