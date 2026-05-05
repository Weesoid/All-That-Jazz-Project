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

@onready var stat_text = $Stat
@onready var value = $Value
@onready var bar = $Value/ProgressBar
@onready var bar_values = $Value/ProgressBar/MaxValues
@onready var count_bar = $Value/CustomCountBar
@onready var label = $Value/Label

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
		tooltip_text = CombatExtras.STAT_DESCRIPTIONS[track_stat]
	
func _process(delta):
	if combatant == null:
		return
	if combatant.stat_values[track_stat] == 0.0 and !CombatExtras.BASE_STATS.has(track_stat):
		hide()
	else:
		show()
	#CombatGlobals.OtherStats['']
	if combatant.scale_stats.get(track_stat,0) > 0:
		stat_text.text = scale_bb+' '+track_stat.to_upper()
	else:
		stat_text.text = track_stat.to_upper()
	
	match visual:
		StatVisuals.BAR: updateBar()
		StatVisuals.COUNT_BAR: updateCountBar()
		StatVisuals.LABEL: updateLabel()
	highlightChange()

func updateBar():
	bar.value = combatant.stat_values[track_stat]
	if bar_base_stat_as_max:
		bar.max_value = combatant.base_stat_values[track_stat]
		bar_values.text = '%s/%s' % [combatant.stat_values[track_stat], combatant.base_stat_values[track_stat]]
	else:
		bar.max_value = 1.0

func updateCountBar():
	count_bar.value = combatant.stat_values[track_stat]
	if count_bar_max_value == -1:
		count_bar.max_value = combatant.base_stat_values[track_stat]
	else:
		count_bar.max_value = count_bar_max_value

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
	var damage = combatant.stat_values['damage']*combatant.stat_values.get(CombatExtras.DAMAGE_MODIFIER,1.0)
	var variance = (damage*combatant.stat_values['dmg_variance'])
	
	match val:
		'min': return round(damage-variance)
		'max': return round(damage+variance)

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
	return combatant.stat_values[track_stat] - combatant.stat_modifiers['scaled_stats'].get(track_stat,0)

#func checkAgainst():
#	if combatant.base_stat_values.has(track_stat):
#		return combatant.stat_values[track_stat] == combatant.base_stat_values[track_stat]
#	elif combatant.stat_values 
