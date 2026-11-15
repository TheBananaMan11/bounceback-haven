extends Node2D

# Runs the 5 waves. Each wave, boats park on the shore and the enemies land next to them.


signal wave_started(wave: int)
signal wave_cleared(wave: int)

# [chickens, cows] per wave.
const WAVES = [[6, 0], [8, 1], [11, 3], [12, 5], [14, 6]]
const BOATS_PER_WAVE = [1, 2, 2, 3, 4]
const SPAWN_INTERVALS = [1.2, 1.1, 1.0, 1.0, 0.9]   # seconds between enemies, per wave
const TWO_SIDES_FROM_WAVE = 4   # from this wave on, boats land on opposite sides of the island
const BOAT_SPREAD = 0.4         # radians between boats on the same side
const SHORE_STEP = 16.0         # how finely the shoreline is searched
const LANDING_INSET = 48.0      # how far inland enemies appear
const LANDING_SCATTER = 56.0    # random sideways spread around a boat
const BOAT_OFFSET = 72.0        # how far out in the water a boat sits

@export var chicken_scene: PackedScene
@export var cow_scene: PackedScene
@export var boat_scene: PackedScene

var spawn_queue: Array[PackedScene] = []
var landing_angles: Array[float] = []
var is_running: bool = false

@onready var spawn_timer: Timer = $SpawnTimer
@onready var boats: Node2D = $Boats
@onready var enemies: Node2D = $Enemies


func _physics_process(_delta: float) -> void:
	if not is_running:
		return

	Game.enemies_left = spawn_queue.size() + enemies.get_child_count()

	# Wave over when everything has landed and is gone.
	if Game.enemies_left == 0:
		finish_wave()



# --------------------------------------------------
# WAVES
# --------------------------------------------------

func start_next_wave() -> void:
	if is_running or Game.wave >= WAVES.size():
		return

	Game.wave += 1
	Game.start_wave_tally()

	var counts: Array = WAVES[Game.wave - 1]
	spawn_queue.clear()
	for i in counts[0]:
		spawn_queue.append(chicken_scene)
	for i in counts[1]:
		spawn_queue.append(cow_scene)
	spawn_queue.shuffle()

	place_boats(BOATS_PER_WAVE[Game.wave - 1])
	Game.enemies_left = spawn_queue.size()
	is_running = true
	spawn_timer.start(SPAWN_INTERVALS[Game.wave - 1])
	wave_started.emit(Game.wave)


func finish_wave() -> void:
	is_running = false
	spawn_timer.stop()
	for boat in boats.get_children():
		boat.queue_free()   # the boats leave
	wave_cleared.emit(Game.wave)



# --------------------------------------------------
# BOATS AND LANDING
# --------------------------------------------------

# One side of the island early on, two opposite sides later.
func place_boats(count: int) -> void:
	landing_angles.clear()
	var sides: int = 2 if Game.wave >= TWO_SIDES_FROM_WAVE else 1
	var per_side: int = ceili(float(count) / sides)
	var base_angle := randf() * TAU

	for i in count:
		var side: int = i % sides
		var slot: int = i / sides
		var angle := base_angle + side * PI + (slot - (per_side - 1) / 2.0) * BOAT_SPREAD
		landing_angles.append(angle)

		var boat: Node2D = boat_scene.instantiate()
		boat.global_position = find_shore_point(angle) + Vector2.from_angle(angle) * BOAT_OFFSET
		boat.rotation = snappedf(angle - PI / 2.0, PI / 2.0)   # points at the island, kept square so the pixels stay crisp
		boats.add_child(boat)


func get_island_centre() -> Vector2:
	if is_instance_valid(Game.house):
		return Game.house.global_position
	return global_position


# Walks out from the middle of the island until the grass ends.
func find_shore_point(angle: float) -> Vector2:
	var direction := Vector2.from_angle(angle)
	var point := get_island_centre()
	for i in 400:
		if not Game.is_on_land(point + direction * SHORE_STEP):
			break
		point += direction * SHORE_STEP
	return point


func get_landing_position() -> Vector2:
	var angle: float = landing_angles.pick_random() if not landing_angles.is_empty() else randf() * TAU
	var direction := Vector2.from_angle(angle)
	var landing := find_shore_point(angle) - direction * LANDING_INSET
	var scattered := landing + direction.orthogonal() * randf_range(-LANDING_SCATTER, LANDING_SCATTER)
	return scattered if Game.is_on_land(scattered) else landing


func spawn_enemy(enemy_scene: PackedScene) -> Node2D:
	var enemy: Node2D = enemy_scene.instantiate()
	enemy.position = enemies.to_local(get_landing_position())
	enemies.add_child(enemy)
	return enemy


func _on_spawn_timer_timeout() -> void:
	if spawn_queue.is_empty():
		spawn_timer.stop()
		return
	spawn_enemy(spawn_queue.pop_back())
