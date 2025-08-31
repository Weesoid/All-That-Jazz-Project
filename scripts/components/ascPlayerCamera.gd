extends DynamicCamera
class_name PlayerCamera

@onready var ammo_count = $UI/Ammo
@onready var crystal_count = $UI/VoidCrystals
@onready var prompt = $UI/PlayerPrompt
@onready var cinematic_bars = $CinematicBars
@onready var stamina_bar = $UI/StaminaBar
@onready var power_input_container = $UI/PowerInputs
@onready var quiver = $UI/Quiver
@onready var color_overlay = $UI/ColorOverlay
@onready var reward_banks = $UI/ClearProgress
@onready var ammo_tex = $UI/Ammo/TextureRect
var player: PlayerScene = OverworldGlobals.player

func _ready():
	if SaveLoadGlobals.is_loading:
		await SaveLoadGlobals.done_loading
	player = OverworldGlobals.player

func _process(delta):
	if player == null:
		return
	if shake_strength != 0:
		shake_strength = lerpf(shake_strength, 0, shake_speed * delta)
		offset = Vector2(randf_range(-shake_strength,shake_strength), randf_range(-shake_strength,shake_strength))
	# TO DO: Move this to input..!
	if player.bow_mode:
		ammo_count.show()
		ammo_count.text = str(PlayerGlobals.equipped_arrow.stack)
		ammo_tex.texture = PlayerGlobals.equipped_arrow.icon
	else:
		ammo_count.hide()

func _input(_event):
	if player == null:
		return
	
	if player.canUsePower() and InventoryGlobals.hasItem('Void Resonance Crystal'):
		crystal_count.show()
		crystal_count.text = str(InventoryGlobals.getItem('Void Resonance Crystal').stack)

func flashStamina(color:Color):
	var tween = create_tween().chain()
	tween.tween_property(stamina_bar, 'modulate',color,0.25)
	tween.tween_property(stamina_bar, 'modulate',Color.WHITE,0.25)

func addPowerInput(icon: TextureRect):
	power_input_container.add_child(icon)
	var tween = create_tween().bind_node(icon).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(icon, 'scale', Vector2(1.25,1.25), 0.1)
	tween.tween_property(icon, 'scale', Vector2(1.0,1.0), 0.25)
	tween.tween_callback(tween.kill)
	tween.tween_callback(icon.queue_free)

func showOverlay(color: Color, alpha:float, duration:float=0.25):
	color_overlay.modulate = Color.TRANSPARENT
	color_overlay.show()
	await create_tween().tween_property(color_overlay, 'modulate', Color(color, alpha), duration).finished

func hideOverlay(duration:float=0.25):
	await create_tween().tween_property(color_overlay, 'modulate', Color.TRANSPARENT, duration).finished
	color_overlay.hide()
	color_overlay.modulate = Color.TRANSPARENT

func addRewardBank(patroller_group: PatrollerGroup):
	for bank in reward_banks.get_children():
		if bank.patroller_group == patroller_group:
			bank.updateBank(patroller_group.reward_bank)
			return
	
	var bank_ui = load("res://scenes/user_interface/RewardBank.tscn").instantiate()
	bank_ui.patroller_group = patroller_group
	reward_banks.add_child(bank_ui)
	bank_ui.updateBank(patroller_group.reward_bank)

func clearRewardBanks():
	for child in reward_banks.get_children():
		child.queue_free()
