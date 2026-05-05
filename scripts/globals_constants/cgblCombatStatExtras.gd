extends Node

const HEAL_SKILL = 'heal_skill' # Percent increase to heal skill
const REBUKE_CHANCE = 'rebuke_chance' 
const DAMAGE_MODIFIER = 'dmg_modifier'

# To be implemented:
const EXECUTE = 'execute_dmg'
const RIPOSTE_DMG = 'riposte_dmg'

const STAT_DESCRIPTIONS = {
	"health": "Damage character can sustain before entering brink.", 
	"damage": "Damage character deals.", 
	"handling": "Max rank of combat item character can use.", 
	"speed": "Determiness turn order priority.", 
	"crit": "Chance to land a critical blow.",
	"resist": "Chance to resist negative effects.", 
	"resolve": "Hits character can take before getting incapacitated.",
	"strain": "Item consumption limit.",
	HEAL_SKILL: 'Percentage increase to healing skills',
	REBUKE_CHANCE: 'Chance to execute a rebuke.',
	DAMAGE_MODIFIER: 'Percentage modification to damage.'
}
const BASE_STATS = [
	"health", 
	"damage", 
	"handling", 
	"speed", 
	"crit",
	"resist", 
	"resolve",
	"strain",
	"rebuke_chance"
]
