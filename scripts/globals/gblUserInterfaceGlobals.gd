extends Node

func addTooltip(control:Control, text:String, tooltip_position:CustomTooltip.AnchorPreset,show_on_hover:bool=true):
	if !is_instance_valid(control):
		return
	
	var tooltip:CustomTooltip = load("res://scenes/user_interface/CustomTooltip.tscn").instantiate()
	tooltip.tooltip_position = tooltip_position
	tooltip.show_on_hover = show_on_hover
	control.add_child(tooltip)
	await get_tree().process_frame
	tooltip.setText(text)
	addFocusMode(control)

func addFocusMode(control:Control):
	control.focus_mode = Control.FOCUS_ALL
	control.focus_entered.connect(func():control.modulate=Color.YELLOW)
	control.mouse_entered.connect(func():control.grab_focus())
	control.focus_exited.connect(func():control.modulate=Color.WHITE)
