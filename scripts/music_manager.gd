extends AudioStreamPlayer2D

func play_music(track: AudioStream):
	if stream == track and playing:
		return  # already playing, don't restart
	stream = track
	play()

func stop_music():
	stop()
