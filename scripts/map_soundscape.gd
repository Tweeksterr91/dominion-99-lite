extends Node
## Original quiet, looping soundscapes; effects retain their own volume control.
const TRACKS := ["verdant_circuit","cold_reliquary","ember_pressure","root_signal","tidal_relay"]
var music: AudioStreamPlayer
var ambience: AudioStreamPlayer
var map_id := -1
var music_level := 0.7
var ambience_level := 0.5
var suspended := false
func _ready() -> void:
	music = AudioStreamPlayer.new()
	music.name = "MapMusic"
	add_child(music)
	ambience = AudioStreamPlayer.new()
	ambience.name = "BrownAmbience"
	add_child(ambience)
	ambience.stream = _loop("brown_ambience")
	ambience.volume_db = -60
	ambience.play()
func _loop(name: String) -> AudioStreamOggVorbis:
	var stream: AudioStreamOggVorbis = load("res://assets/audio/"+name+".ogg")
	stream.loop = true
	return stream
func set_map(value: int) -> void:
	value = clampi(value,0,4)
	if value==map_id:return
	map_id = value
	music.stream = _loop(TRACKS[value])
	music.volume_db = -60
	music.play()
func configure(music_volume: float,ambience_volume: float,paused: bool) -> void:
	music_level = clampf(music_volume,0,1)
	ambience_level = clampf(ambience_volume,0,1)
	suspended = paused
	music.stream_paused = suspended or music_level==0
	ambience.stream_paused = suspended or ambience_level==0
func _process(delta: float) -> void:
	music.volume_db = move_toward(music.volume_db,-10+linear_to_db(maxf(0.001,music_level)),delta*45)
	ambience.volume_db = move_toward(ambience.volume_db,-22+linear_to_db(maxf(0.001,ambience_level)),delta*45)

func shutdown() -> void:
	for player in [music,ambience]:
		if is_instance_valid(player):
			player.stream_paused = false
			player.stop()
			player.stream = null

func _exit_tree() -> void:
	shutdown()
