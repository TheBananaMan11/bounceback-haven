extends Node2D

# The house in the centre of the island. Enemies walk to it and smash it.
# Its lives are kept in Game.house_lives so the HUD and shop can show them.


signal was_hit(fence_absorbed: bool)

const DAMAGED_COLOR = Color("#8a6a5c")

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var fence: Node2D = $Fence


func _ready() -> void:
	Game.loadout_changed.connect(update_fence)
	Game.lives_changed.connect(update_damage)
	update_fence()
	update_damage()


# Called by an enemy that reaches the house.
func take_hit() -> void:
	# The fence is one extra chance. Without it the house loses a life,
	# and at 0 lives the game is over.
	var fence_absorbed := Game.damage_house()
	was_hit.emit(fence_absorbed)
	Sfx.play("fence_break" if fence_absorbed else "house_hit")
	play_hit_flash()


func update_fence() -> void:
	fence.visible = Game.has_fence


# The house gets darker with every life it loses.
func update_damage() -> void:
	var damage := float(Game.HOUSE_MAX_LIVES - Game.house_lives) / float(Game.HOUSE_MAX_LIVES)
	sprite_2d.self_modulate = Color.WHITE.lerp(DAMAGED_COLOR, damage)


func play_hit_flash() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.0, 0.4, 0.4), 0.06)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
