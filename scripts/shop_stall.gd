extends Node2D

# The pop-up shop stall. It pops in next to the house when a round ends and leaves when the
# next wave starts. Stand near it and press E (the "interact" action) to open the shop panel.


const INTERACT_RANGE = 240.0
const POP_IN_TIME = 0.4
const POP_OUT_TIME = 0.2
# Where to try putting the stall, relative to the house. The first spot that is on grass wins.
const SPOT_OFFSETS = [Vector2(320, 90), Vector2(-320, 90), Vector2(0, 340), Vector2(0, -300)]
const CLEARANCE = 100.0   # the spot and the ground this far around it must be grass

var is_open: bool = false
var tween: Tween

@onready var prompt_label: Label = $PromptLabel
@onready var collision_shape_2d: CollisionShape2D = $StaticBody2D/CollisionShape2D


func _ready() -> void:
	hide()
	scale = Vector2.ZERO
	collision_shape_2d.disabled = true


func _physics_process(_delta: float) -> void:
	prompt_label.visible = is_open and is_player_near()


# --------------------------------------------------
# OPENING AND CLOSING
# --------------------------------------------------

func appear() -> void:
	if is_open:
		return
	is_open = true
	global_position = find_spot()
	collision_shape_2d.set_deferred("disabled", false)
	show()

	# Pops in with a little overshoot.
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, POP_IN_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func disappear() -> void:
	if not is_open:
		return
	is_open = false
	prompt_label.hide()
	collision_shape_2d.set_deferred("disabled", true)

	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, POP_OUT_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(hide)


# --------------------------------------------------
# POSITION AND INTERACTION
# --------------------------------------------------

func find_spot() -> Vector2:
	var house_position := global_position
	if is_instance_valid(Game.house):
		house_position = Game.house.global_position

	for offset in SPOT_OFFSETS:
		var spot: Vector2 = house_position + offset
		if is_spot_on_grass(spot):
			return spot
	return house_position + SPOT_OFFSETS[0]


func is_spot_on_grass(spot: Vector2) -> bool:
	for check in [Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		if not Game.is_on_land(spot + check * CLEARANCE):
			return false
	return true


func is_player_near() -> bool:
	var player := Game.player
	if not is_instance_valid(player):
		return false
	return global_position.distance_to(player.global_position) <= INTERACT_RANGE


func can_interact() -> bool:
	return is_open and is_player_near()
