#@tool
extends HSplitContainer
class_name StatLabel

enum StatVisuals {
	BAR,
	COUNT_BAR,
	LABEL
}
enum LabelStyle {
	FLAT,
	PERCENTAGE,
	DAMAGE_RANGE
}

@export var combatant: ResCombatant
@export var track_stat: String
@export var visual: StatVisuals
@export var bar_base_stat_as_max:bool
@export var count_bar_max_value: int = -1
@export var label_style:LabelStyle
@export var label_percentage_reduce_by_100:bool=false
@export var highlight_increase:bool=true
@export var highlight_decrease:bool=true
@export var tooltip_pos: CustomTooltip.AnchorPreset = CustomTooltip.AnchorPreset.LEFT

@onready var stat_text = $Stat
@onready var value = $Value
@onready var bar = $Value/ProgressBar
@onready var bar_values = $Value/ProgressBar/MaxValues
@onready var count_bar = $Value/CustomCountBar
@onready var label = $Value/Label
#@onready var tooltip = $CustomTooltip
var scale_bb = '[img color=%s]res://images/status_icons/small_buff.png[/img]'%SettingsGlobals.ui_colors['up-bb-nobracket']

func _ready():
	track_stat = track_stat.to_lower()
	bar.hide()
	count_bar.hide()
	label.hide()
	if bar_base_stat_as_max:
		bar.show_percentage=false
		bar_values.show()
	
	match visual:
		StatVisuals.BAR: bar.show()
		StatVisuals.COUNT_BAR: count_bar.show()
		StatVisuals.LABEL: label.show()
	
	if CombatExtras.STAT_DESCRIPTIONS.has(track_stat):
		UIGlobals.addTooltip(
			self,
			CombatExtras.STAT_DESCRIPTIONS[track_stat],
			tooltip_pos
			)
		#tooltip.setText(CombatExtras.STAT_DESCRIPTIONS[track_stat])
		#tooltip_text = CombatExtras.STAT_DESCRIPTIONS[track_stat]
	if combatant != null:
		setCombatant(combatant)

func setCombatant(p_combatant):
	if combatant != null:
		if combatant.stat_modified.is_connected(update):
			combatant.stat_modified.disconnect(update)
		if combatant.stat_removed.is_connected(update):
			combatant.stat_removed.disconnect(update)
	
	combatant = p_combatant
	if !combatant.stat_modified.is_connected(update):
		combatant.stat_modified.connect(update.unbind(2))
	if !combatant.stat_removed.is_connected(update):
		combatant.stat_removed.connect(update.unbind(2))
	update()

func update():
	await get_tree().process_frame
	if combatant == null or !combatant.stat_values.has(track_stat):
		hide()
		return
	
	if combatant.stat_values[track_stat] == 0 and !CombatExtras.BASE_STATS.has(track_stat):
		hide()
	else:
		show()
	
	if combatant.scale_stats.get(track_stat,0) > 0:
		stat_text.text = scale_bb+' '+SettingsGlobals.longhandWord(track_stat).to_upper()
	else:
		stat_text.text = SettingsGlobals.longhandWord(track_stat).to_upper()
	
	await get_tree().process_frame
	match visual:
		StatVisuals.BAR: 
			updateBar()
		StatVisuals.COUNT_BAR: updateCountBar()
		StatVisuals.LABEL: updateLabel()
	highlightChange()

func updateBar():
	if bar_base_stat_as_max:
		bar.max_value = combatant.base_stat_values[track_stat]
		bar_values.text = '%s/%s' % [combatant.stat_values[track_stat], combatant.base_stat_values[track_stat]]
	else:
		bar.max_value = 1.0
	bar.value = combatant.stat_values[track_stat]

func updateCountBar():
	if count_bar_max_value == -1:
		count_bar.setMax(combatant.base_stat_values[track_stat])
	elif count_bar.max_value != count_bar_max_value:
		count_bar.setMax(count_bar_max_value)
	#await get_tree().create_timer(0.25).timeout
	count_bar.setValue(combatant.stat_values[track_stat])
#	count_bar.value = combatant.stat_values[track_stat]

func updateLabel():
	match label_style:
		LabelStyle.FLAT: label.text = str(combatant.stat_values[track_stat])
		LabelStyle.PERCENTAGE: 
			if label_percentage_reduce_by_100:
				label.text = str(round((combatant.stat_values[track_stat]*100)-100))+'%'
			else:
				label.text = str(round((combatant.stat_values[track_stat]*100)))+'%'
		LabelStyle.DAMAGE_RANGE: label.text = str('%s - %s' % [calcDamage('min'),calcDamage('max')])

func calcDamage(val:String):
	var damage = combatant.stat_values['damage']*CombatGlobals.calcDamageModifier(combatant)
	var dmg_variation = CombatGlobals.BASE_VARIATION + combatant.stat_values['dmg_variance']
	var variance = damage*dmg_variation
	
	match val:
		'min': return max(round(damage-variance), 1)
		'max': return max(round(damage+variance), 1)

func highlightChange():
	if !combatant.base_stat_values.has(track_stat):
		return
	
	var base_stat_value
	if combatant.base_stat_values.has(track_stat):
		base_stat_value = combatant.base_stat_values[track_stat]
	elif count_bar_max_value > 0:
		base_stat_value = count_bar_max_value
	#if track_stat == 'handling' and combatant.name.contains('Willis'): print(getUnscaledTrackStat())
	if is_equal_approx(getUnscaledTrackStat(), base_stat_value):
		value.modulate = Color.WHITE
	elif getUnscaledTrackStat() > base_stat_value and highlight_increase:
		value.modulate = SettingsGlobals.ui_colors['up']
	elif getUnscaledTrackStat() < base_stat_value and highlight_decrease:
		value.modulate = SettingsGlobals.ui_colors['down']

func getUnscaledTrackStat():
#	if !combatant.stat_modifiers.has('scaled_stats'):
#		return 0
	
	return combatant.stat_values[track_stat] - combatant.stat_modifiers['scaled_stats'].get(track_stat,0)

#func _on_focus_entered():
#	modulate = Color.YELLOW
#
#func _on_focus_exited():
#	modulate = Color.WHITE
#
#
#func _on_mouse_entered():
#	grab_focus()
