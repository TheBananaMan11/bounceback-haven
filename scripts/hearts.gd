extends Control

# The house's lives, drawn as pixel hearts. Lost lives stay as dark hearts.


const PIXEL = 4.0   # same 4x scale as the sprites
const GAP = 36.0
const FULL_COLOR = Color("#e0434f")
const EMPTY_COLOR = Color(0.0, 0.0, 0.0, 0.4)
const HEART = [
	".XX.XX.",
	"XXXXXXX",
	"XXXXXXX",
	".XXXXX.",
	"..XXX..",
	"...X...",
]


func _ready() -> void:
	Game.lives_changed.connect(queue_redraw)


func _draw() -> void:
	for i in Game.HOUSE_MAX_LIVES:
		var color := FULL_COLOR if i < Game.house_lives else EMPTY_COLOR
		draw_heart(Vector2(i * GAP, 0.0), color)


func draw_heart(origin: Vector2, color: Color) -> void:
	for y in HEART.size():
		for x in HEART[y].length():
			if HEART[y][x] == "X":
				draw_rect(Rect2(origin + Vector2(x, y) * PIXEL, Vector2(PIXEL, PIXEL)), color)
