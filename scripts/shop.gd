extends CanvasLayer

# The shop panel. It pops up by itself when a round ends (and before wave 1), and can be
# reopened at the shop stall. Buy the hoe, the axe or a fence, then start the next wave.


signal next_wave_pressed

const LOCK_TIME = 0.4   # buttons ignore presses for a moment after opening, so mashing the
						# attack key at the last enemy can't buy or start a wave by accident

var cleared_wave: int = 0
var lock_timer: float = 0.0
var tween: Tween

@onready var panel_container: PanelContainer = $CenterContainer/PanelContainer
@onready var title_label: Label = %TitleLabel
@onready var tally_label: Label = %TallyLabel
@onready var money_label: Label = %MoneyLabel
@onready var watering_can_button: Button = %WateringCanButton
@onready var hoe_button: Button = %HoeButton
@onready var axe_button: Button = %AxeButton
@onready var fence_button: Button = %FenceButton
@onready var next_wave_button: Button = %NextWaveButton
@onready var close_button: Button = %CloseButton


func _ready() -> void:
	Game.money_changed.connect(update_shop)
	Game.loadout_changed.connect(update_shop)
	panel_container.resized.connect(update_pivot)
	hide()


func _process(delta: float) -> void:
	lock_timer = max(lock_timer - delta, 0.0)


# wave = the wave that was just cleared, or 0 before the first one.
func open(wave: int) -> void:
	cleared_wave = wave
	update_shop()
	lock_timer = LOCK_TIME
	show()
	play_pop_in()


func close() -> void:
	hide()


func update_pivot() -> void:
	panel_container.pivot_offset = panel_container.size / 2.0


# The panel pops in from slightly smaller with a little overshoot.
func play_pop_in() -> void:
	update_pivot()
	panel_container.scale = Vector2(0.8, 0.8)
	panel_container.modulate.a = 0.0

	if tween:
		tween.kill()
	tween = create_tween().set_parallel(true)
	tween.tween_property(panel_container, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel_container, "modulate:a", 1.0, 0.15)


func update_shop() -> void:
	if cleared_wave == 0:
		title_label.text = "Get ready!"
		tally_label.text = "Smack the invaders into the water\nbefore they reach your house."
	else:
		title_label.text = "Wave %d cleared!" % cleared_wave
		tally_label.text = "Drowned: %d    Earned: $%d" % [Game.wave_drowned, Game.wave_earned]

	money_label.text = "Money: $%d    House lives: %d/%d" % [Game.money, Game.house_lives, Game.HOUSE_MAX_LIVES]

	update_weapon_button(watering_can_button, 0)
	update_weapon_button(hoe_button, 1)
	update_weapon_button(axe_button, 2)

	if Game.has_fence:
		fence_button.text = "Fence built (blocks 1 hit)"
		fence_button.disabled = true
	else:
		fence_button.text = "Buy Fence - $%d (blocks 1 hit)" % Game.FENCE_PRICE
		fence_button.disabled = not Game.can_buy_fence()

	next_wave_button.text = "Start wave %d" % (cleared_wave + 1)


func update_weapon_button(button: Button, index: int) -> void:
	var weapon_name: String = Game.WEAPON_NAMES[index]
	var knockback: int = Game.WEAPON_KNOCKBACK[index]

	if Game.owned_weapons[index] and Game.weapon == index:
		button.text = "%s (equipped, knockback %d)" % [weapon_name, knockback]
		button.disabled = true
	elif Game.owned_weapons[index]:
		button.text = "Equip %s (knockback %d)" % [weapon_name, knockback]
		button.disabled = false
	else:
		button.text = "Buy %s - $%d (knockback %d)" % [weapon_name, Game.WEAPON_PRICES[index], knockback]
		button.disabled = not Game.can_buy_weapon(index)


func is_locked() -> bool:
	return lock_timer > 0.0


func buy_weapon(index: int) -> void:
	var is_new: bool = not Game.owned_weapons[index]
	if Game.buy_weapon(index) and is_new:
		Sfx.play("buy")   # equipping one you already own is silent



# --------------------------------------------------
# BUTTONS
# --------------------------------------------------

func _on_watering_can_button_pressed() -> void:
	if not is_locked():
		buy_weapon(0)


func _on_hoe_button_pressed() -> void:
	if not is_locked():
		buy_weapon(1)


func _on_axe_button_pressed() -> void:
	if not is_locked():
		buy_weapon(2)


func _on_fence_button_pressed() -> void:
	if not is_locked() and Game.buy_fence():
		Sfx.play("buy")


func _on_next_wave_button_pressed() -> void:
	if is_locked():
		return
	close()
	next_wave_pressed.emit()


# Close the panel and walk around. The stall stays until the next wave starts.
func _on_close_button_pressed() -> void:
	close()
