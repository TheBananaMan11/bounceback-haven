extends Node

# Autoload named "Game" (Project Settings > Globals).
# Shared run state: money, wave, the house's lives, and what the shop sells.


signal money_changed
signal lives_changed
signal loadout_changed
signal game_over(message: String, won: bool)

const TOTAL_WAVES = 5
const HOUSE_MAX_LIVES = 3

const KNOCK_UNIT = 1024.0      # launch speed per knockback level (slides 4 tiles per level)
const KNOCK_DECAY = 4.0        # slide distance = launch speed / KNOCK_DECAY
const MIN_KNOCK_LEVEL = 0.75   # a weapon weaker than the enemy's resistance still nudges it

const WEAPON_NAMES = ["Watering Can", "Hoe", "Axe"]
const WEAPON_KNOCKBACK = [1, 2, 3]
const WEAPON_PRICES = [0, 60, 120]
const FENCE_PRICE = 30

var money: int = 0
var wave: int = 0
var weapon: int = 0
var owned_weapons: Array[bool] = [true, false, false]
var has_fence: bool = false
var house_lives: int = HOUSE_MAX_LIVES
var is_finished: bool = false

# Tally for the wave that is running or just ended (shown in the shop).
var wave_drowned: int = 0
var wave_earned: int = 0
var enemies_left: int = 0

# Set by main.gd when the level loads.
var grass_tilemap: TileMapLayer
var player: CharacterBody2D
var house: Node2D

var player_push: Vector2 = Vector2.ZERO


func _physics_process(delta: float) -> void:
	process_player_push(delta)


func reset() -> void:
	money = 0
	wave = 0
	weapon = 0
	owned_weapons = [true, false, false]
	has_fence = false
	house_lives = HOUSE_MAX_LIVES
	is_finished = false
	wave_drowned = 0
	wave_earned = 0
	enemies_left = 0
	player_push = Vector2.ZERO
	money_changed.emit()
	lives_changed.emit()
	loadout_changed.emit()



# --------------------------------------------------
# MONEY AND SHOP
# --------------------------------------------------

func add_money(amount: int) -> void:
	money += amount
	money_changed.emit()


# Called by an enemy when it drowns.
func record_drowning(payout: int) -> void:
	wave_drowned += 1
	wave_earned += payout
	add_money(payout)


func start_wave_tally() -> void:
	wave_drowned = 0
	wave_earned = 0


func can_buy_weapon(index: int) -> bool:
	return not owned_weapons[index] and money >= WEAPON_PRICES[index]


# Weapons are bought once and kept. Buying or picking an owned one equips it.
func buy_weapon(index: int) -> bool:
	if not owned_weapons[index]:
		if money < WEAPON_PRICES[index]:
			return false
		money -= WEAPON_PRICES[index]
		owned_weapons[index] = true
		money_changed.emit()
	weapon = index
	loadout_changed.emit()
	return true


func can_buy_fence() -> bool:
	return not has_fence and money >= FENCE_PRICE


# The fence blocks one hit on the house, then it is gone and can be bought again.
func buy_fence() -> bool:
	if not can_buy_fence():
		return false
	money -= FENCE_PRICE
	has_fence = true
	money_changed.emit()
	loadout_changed.emit()
	return true



# --------------------------------------------------
# LIVES
# --------------------------------------------------

# Returns true if the fence took the hit instead of the house.
func damage_house() -> bool:
	if has_fence:
		has_fence = false
		loadout_changed.emit()
		return true
	house_lives = max(house_lives - 1, 0)
	lives_changed.emit()
	if house_lives <= 0:
		end_game("Your house was destroyed!", false)
	return false


func end_game(message: String, won: bool) -> void:
	if is_finished:
		return
	is_finished = true
	game_over.emit(message, won)
	get_tree().paused = true



# --------------------------------------------------
# ISLAND
# --------------------------------------------------

# True if this world position is on a grass tile. Anything else is water.
func is_on_land(world_position: Vector2) -> bool:
	if not is_instance_valid(grass_tilemap):
		return true
	var cell := grass_tilemap.local_to_map(grass_tilemap.to_local(world_position))
	return grass_tilemap.get_cell_source_id(cell) != -1


# Shoves the player (cows do this). The push fades out the same way enemy knockback does.
func push_player(direction: Vector2, level: float) -> void:
	player_push = direction * level * KNOCK_UNIT


func process_player_push(delta: float) -> void:
	if player_push == Vector2.ZERO or not is_instance_valid(player):
		return
	player.global_position += player_push * delta
	player_push = player_push.lerp(Vector2.ZERO, 1.0 - exp(-KNOCK_DECAY * delta))
	if player_push.length() < 10.0:
		player_push = Vector2.ZERO
