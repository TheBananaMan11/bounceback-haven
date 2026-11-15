extends CanvasLayer

# Wave, money, weapon and lives on screen, the wave banner, and the game over screen.


@onready var info_label: Label = %InfoLabel
@onready var fence_icon: TextureRect = %FenceIcon
@onready var wave_banner: Label = %WaveBanner
@onready var game_over_panel: Control = %GameOverPanel
@onready var result_label: Label = %ResultLabel
@onready var message_label: Label = %MessageLabel
@onready var play_again_button: Button = %PlayAgainButton


func _ready() -> void:
	Game.game_over.connect(show_game_over)
	game_over_panel.hide()
	wave_banner.modulate.a = 0.0


func _process(_delta: float) -> void:
	update_info()


func update_info() -> void:
	info_label.text = "Wave %d/%d    $%d    %s    Enemies: %d" % [
		Game.wave, Game.TOTAL_WAVES, Game.money, Game.WEAPON_NAMES[Game.weapon], Game.enemies_left]
	fence_icon.visible = Game.has_fence


# "Wave 3" splashes across the screen, then fades.
func show_wave_banner(wave: int) -> void:
	wave_banner.text = "Wave %d" % wave
	wave_banner.modulate.a = 1.0
	var tween := wave_banner.create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(wave_banner, "modulate:a", 0.0, 0.6)


func show_game_over(message: String, won: bool) -> void:
	result_label.text = "YOU WIN!" if won else "GAME OVER"
	message_label.text = message
	game_over_panel.show()
	play_again_button.grab_focus()


func _on_play_again_button_pressed() -> void:
	Game.reset()
	get_tree().paused = false
	get_tree().reload_current_scene()
