extends Control

@onready var playbutton: Button = $playbutton
@onready var exitbutton: Button = $exitbutton

func _ready() -> void:
	MusicManager.play_music(preload("res://assets/music/idle.ogg"))

func _on_playbutton_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_exitbutton_pressed() -> void:
	get_tree().quit()
	
