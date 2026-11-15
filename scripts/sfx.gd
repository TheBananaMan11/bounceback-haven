extends Node

# Autoload named "Sfx". Plays one-shot sound effects by name: Sfx.play("splash").
# Put the files in res://assets/sounds/ named like the list below (.ogg, .wav or .mp3).
# A sound whose file is missing just plays nothing.


const SOUND_FOLDER = "res://assets/sounds/"
const SOUND_NAMES = [
	"swing",         # the player swings a weapon
	"hit",           # a weapon hits an animal
	"splash",        # an animal lands in the water
	"house_hit",     # an animal reaches the house
	"fence_break",   # the fence takes the hit and breaks
	"buy",           # something is bought in the shop
]
const EXTENSIONS = [".ogg", ".wav", ".mp3"]
const MAX_VOICES = 8          # how many sounds can overlap
const PITCH_VARIATION = 0.1   # so repeated sounds don't sound identical

var streams: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var next_voice: int = 0
var player_was_attacking: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # shop and game over sounds still play while paused
	load_sounds()
	for i in MAX_VOICES:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)


func _physics_process(_delta: float) -> void:
	check_player_swing()


func load_sounds() -> void:
	for sound_name in SOUND_NAMES:
		for extension in EXTENSIONS:
			var path: String = SOUND_FOLDER + sound_name + extension
			if ResourceLoader.exists(path):
				streams[sound_name] = load(path)
				break


func play(sound_name: String) -> void:
	if not streams.has(sound_name):
		return
	var voice := voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	voice.stream = streams[sound_name]
	voice.pitch_scale = randf_range(1.0 - PITCH_VARIATION, 1.0 + PITCH_VARIATION)
	voice.play()


# The player's script only sets is_attacking, so the swing sound is triggered from here.
func check_player_swing() -> void:
	var player := Game.player
	if not is_instance_valid(player):
		player_was_attacking = false
		return
	var is_attacking: bool = player.get("is_attacking") == true
	if is_attacking and not player_was_attacking:
		play("swing")
	player_was_attacking = is_attacking
