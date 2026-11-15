extends CharacterBody2D

# Shared by chicken.tscn and cow.tscn. The stats are set per scene in the Inspector.
# Enemies have no health: the only way to beat one is to knock it into the water.


signal drowned(payout: int)

const STUN_SPEED = 60.0        # knocked faster than this = flying, can't walk
const ATTACK_REACH = 130.0     # how far the player's swing reaches
const ATTACK_ARC = 0.2         # 1.0 = thin line in front of the player, 0.0 = half circle
const HOUSE_REACH = 90.0       # this close to the house = it takes a hit
const SHOVE_REACH = 80.0
const SHOVE_COOLDOWN = 1.0

@export var speed: float = 125.0
@export var knockback_resistance: int = 0   # taken off the weapon's knockback
@export var bounty: int = 5                 # money for a drowning
@export var player_knockback: float = 0.0   # knockback dealt to the player (cows)

var knockback: Vector2 = Vector2.ZERO
var was_smacked: bool = false   # only smacked enemies can drown, so no free money
var is_drowning: bool = false
var player_was_attacking: bool = false
var shove_timer: float = 0.0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(delta: float) -> void:
	if is_drowning:
		return

	check_player_attack()
	process_movement(delta)
	process_animation(delta)
	move_and_slide()

	if was_smacked and not Game.is_on_land(global_position):
		drown()
		return

	check_house()
	process_shove(delta)



# --------------------------------------------------
# MOVEMENT AND ANIMATION
# --------------------------------------------------

func process_movement(delta: float) -> void:
	knockback = knockback.lerp(Vector2.ZERO, 1.0 - exp(-Game.KNOCK_DECAY * delta))

	if is_flying():
		velocity = knockback
	elif is_instance_valid(Game.house):
		velocity = global_position.direction_to(Game.house.global_position) * speed
	else:
		velocity = Vector2.ZERO


func process_animation(delta: float) -> void:
	if is_flying():
		animated_sprite_2d.rotation += 14.0 * delta   # tumbles through the air
		return

	animated_sprite_2d.rotation = 0.0
	if velocity != Vector2.ZERO:
		animated_sprite_2d.play("walk")
		animated_sprite_2d.flip_h = velocity.x < 0    # the sprites face right
	else:
		animated_sprite_2d.play("idle")


func is_flying() -> bool:
	return knockback.length() > STUN_SPEED



# --------------------------------------------------
# GETTING HIT
# --------------------------------------------------

# The player's script only sets is_attacking, so each enemy checks
# if a swing just started while it is in front of the player.
func check_player_attack() -> void:
	var player := Game.player
	if not is_instance_valid(player):
		return

	var is_attacking: bool = player.get("is_attacking") == true
	if is_attacking and not player_was_attacking:
		var facing: Vector2 = player.get("last_direction")
		var to_enemy := global_position - player.global_position
		if to_enemy.length() <= ATTACK_REACH and to_enemy.normalized().dot(facing.normalized()) >= ATTACK_ARC:
			smack(facing.normalized(), Game.WEAPON_KNOCKBACK[Game.weapon])
	player_was_attacking = is_attacking


# level = the weapon's knockback (1, 2 or 3).
func smack(direction: Vector2, level: int) -> void:
	var effective: float = max(float(level - knockback_resistance), Game.MIN_KNOCK_LEVEL)
	knockback = direction * effective * Game.KNOCK_UNIT
	was_smacked = true
	Sfx.play("hit")


# Payout grows from wave 3 on: $5/$10, then $6/$12, $7/$14, $8/$16.
func get_payout() -> int:
	return bounty + int(max(Game.wave - 2, 0) * bounty / 5.0)


func drown() -> void:
	is_drowning = true
	remove_from_group("enemies")

	var payout := get_payout()
	Game.record_drowning(payout)
	show_money_popup(payout)
	Sfx.play("splash")
	drowned.emit(payout)

	# Sink, then disappear.
	var tween := create_tween()
	tween.tween_property(animated_sprite_2d, "scale", Vector2.ZERO, 0.35)
	tween.tween_callback(queue_free)


func show_money_popup(amount: int) -> void:
	var label := Label.new()
	label.text = "+$%d" % amount
	label.z_index = 10
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color("#ffe066"))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	label.position = global_position - Vector2(32, 48)
	get_tree().current_scene.add_child(label)

	var tween := label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 64.0, 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)



# --------------------------------------------------
# ATTACKING
# --------------------------------------------------

# Reaching the house is a smash finisher: the house (or its fence) takes a hit.
func check_house() -> void:
	var house := Game.house
	if not is_instance_valid(house):
		return
	if global_position.distance_to(house.global_position) <= HOUSE_REACH:
		house.take_hit()
		queue_free()


# Cows shove the player toward the edge.
func process_shove(delta: float) -> void:
	shove_timer -= delta
	if player_knockback <= 0.0 or shove_timer > 0.0:
		return

	var player := Game.player
	if not is_instance_valid(player):
		return
	if global_position.distance_to(player.global_position) <= SHOVE_REACH:
		Game.push_player(global_position.direction_to(player.global_position), player_knockback)
		shove_timer = SHOVE_COOLDOWN
