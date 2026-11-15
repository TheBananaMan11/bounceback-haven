extends Node2D

# Connects the island and player to the house, the enemy spawner, the HUD, the shop and its stall.


@export var lose_when_player_leaves_island: bool = true

@onready var grass_tilemap: TileMapLayer = $"Island/Grass Tilemap"
@onready var player: CharacterBody2D = $Island/Player
@onready var house: Node2D = $House
@onready var enemy_spawner: Node2D = $EnemySpawner
@onready var hud: CanvasLayer = $HUD
@onready var shop: CanvasLayer = $Shop
@onready var shop_stall: Node2D = $ShopStall


func _ready() -> void:
	Game.grass_tilemap = grass_tilemap
	Game.player = player
	Game.house = house
	Game.reset()

	# Opening "get ready" screen: the stall is up and the shop panel is open.
	shop_stall.appear()
	shop.open(0)


func _physics_process(_delta: float) -> void:
	# Lose condition: getting knocked (or walking) off the island during a wave.
	if lose_when_player_leaves_island and enemy_spawner.is_running:
		if not Game.is_on_land(player.global_position):
			Game.end_game("You fell off the island!", false)


# E opens the shop when you stand next to the stall, and closes the panel from anywhere.
# Escape closes the panel too.
func _unhandled_input(event: InputEvent) -> void:
	var wants_interact := event.is_action_pressed("interact")
	if shop.visible:
		if wants_interact or event.is_action_pressed("ui_cancel"):
			shop.close()
	elif wants_interact and shop_stall.can_interact():
		shop.open(shop.cleared_wave)


func _on_shop_next_wave_pressed() -> void:
	shop_stall.disappear()
	enemy_spawner.start_next_wave()


func _on_enemy_spawner_wave_started(wave: int) -> void:
	hud.show_wave_banner(wave)


func _on_enemy_spawner_wave_cleared(wave: int) -> void:
	if wave >= Game.TOTAL_WAVES:
		# The boss fight goes here once it exists. For now, surviving every wave wins.
		Game.end_game("Your house survived all %d waves!" % Game.TOTAL_WAVES, true)
	else:
		# Round over: the stall pops up and the shop panel opens by itself.
		shop_stall.appear()
		shop.open(wave)
