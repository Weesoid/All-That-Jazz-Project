extends ResTalent
class_name ResAbilityTalent

enum Apply_Type {
	APPEND,
	OVERRIDE
}

@export var affected_ability: ResAbility
@export var effects: Dictionary


func getRichDescription()-> String:
	var duped_ability = affected_ability.duplicate()
	duped_ability.mutateProperties(effects)
	var mutation_desc = duped_ability.getRichDescription(false)
	
	return name.to_upper()+' - '+SettingsGlobals.ui_colors['up-bb']+affected_ability.name.to_upper()+'[/color]\n'+mutation_desc

func _to_string():
	return str(effects)
